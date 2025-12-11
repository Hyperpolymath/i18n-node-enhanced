# LanguageCladogram - Visualize language family trees from Glottolog data
# SPDX-License-Identifier: AGPL-3.0-or-later

module LanguageCladogram

using JSON3
using HTTP
using DataFrames
using CSV
using Graphs
using CairoMakie
using GraphMakie
using Colors

export LanguageNode, LanguageTree,
       load_glottolog_tree, load_from_json,
       get_subtree, find_language, get_ancestors,
       plot_tree, plot_subtree, export_svg,
       INDO_EUROPEAN, SINO_TIBETAN, AFRO_ASIATIC, NIGER_CONGO,
       get_locale_family, suggest_fallback_locales

# === Data Structures ===

"""
    LanguageNode

A node in the language family tree.
- `id`: Glottolog ID (e.g., "indo1319" for Indo-European)
- `name`: Language/family name
- `iso639_3`: ISO 639-3 code if a language (nothing for families)
- `level`: "family", "language", "dialect"
- `children`: Child nodes
"""
struct LanguageNode
    id::String
    name::String
    iso639_3::Union{String, Nothing}
    level::String
    children::Vector{LanguageNode}
end

"""
    LanguageTree

Root container for a language family tree.
"""
struct LanguageTree
    root::LanguageNode
    index::Dict{String, LanguageNode}  # id -> node
    by_iso::Dict{String, LanguageNode}  # iso639-3 -> node
end

# === Major Language Family Constants ===

const INDO_EUROPEAN = "indo1319"
const SINO_TIBETAN = "sino1245"
const AFRO_ASIATIC = "afro1255"
const NIGER_CONGO = "atla1278"
const AUSTRONESIAN = "aust1307"
const DRAVIDIAN = "drav1251"
const TURKIC = "turk1311"
const URALIC = "ural1272"
const JAPONIC = "japo1237"
const KOREANIC = "kore1284"
const TAI_KADAI = "taik1256"
const AUSTROASIATIC = "aust1305"

# === Loading Functions ===

"""
    load_glottolog_tree(family_id::String) -> LanguageTree

Load a language family tree from Glottolog API.
"""
function load_glottolog_tree(family_id::String)::LanguageTree
    url = "https://glottolog.org/resource/languoid/id/$(family_id).json"

    try
        response = HTTP.get(url)
        data = JSON3.read(String(response.body))
        root = parse_glottolog_node(data)
        return build_tree(root)
    catch e
        @warn "Failed to load from Glottolog API: $e"
        # Return empty tree
        empty_root = LanguageNode(family_id, "Unknown", nothing, "family", [])
        return LanguageTree(empty_root, Dict{String, LanguageNode}(), Dict{String, LanguageNode}())
    end
end

function parse_glottolog_node(data)::LanguageNode
    id = get(data, :id, "unknown")
    name = get(data, :name, "Unknown")
    iso = get(data, :iso639P3code, nothing)
    level = get(data, :level, "family")

    children = LanguageNode[]
    if haskey(data, :children)
        for child in data[:children]
            push!(children, parse_glottolog_node(child))
        end
    end

    return LanguageNode(id, name, iso, level, children)
end

"""
    load_from_json(path::String) -> LanguageTree

Load a pre-downloaded language tree from JSON file.
"""
function load_from_json(path::String)::LanguageTree
    data = JSON3.read(read(path, String))
    root = parse_json_node(data)
    return build_tree(root)
end

function parse_json_node(data)::LanguageNode
    LanguageNode(
        data[:id],
        data[:name],
        get(data, :iso639_3, nothing),
        get(data, :level, "family"),
        [parse_json_node(c) for c in get(data, :children, [])]
    )
end

function build_tree(root::LanguageNode)::LanguageTree
    index = Dict{String, LanguageNode}()
    by_iso = Dict{String, LanguageNode}()

    function traverse(node::LanguageNode)
        index[node.id] = node
        if !isnothing(node.iso639_3)
            by_iso[node.iso639_3] = node
        end
        for child in node.children
            traverse(child)
        end
    end

    traverse(root)
    return LanguageTree(root, index, by_iso)
end

# === Query Functions ===

"""
    find_language(tree::LanguageTree, query::String) -> Union{LanguageNode, Nothing}

Find a language by ID, ISO code, or name.
"""
function find_language(tree::LanguageTree, query::String)::Union{LanguageNode, Nothing}
    # Try by ID
    if haskey(tree.index, query)
        return tree.index[query]
    end

    # Try by ISO code
    if haskey(tree.by_iso, query)
        return tree.by_iso[query]
    end

    # Try by name (case-insensitive)
    query_lower = lowercase(query)
    for (_, node) in tree.index
        if lowercase(node.name) == query_lower
            return node
        end
    end

    return nothing
end

"""
    get_ancestors(tree::LanguageTree, node_id::String) -> Vector{LanguageNode}

Get the ancestor chain from root to the given node.
"""
function get_ancestors(tree::LanguageTree, node_id::String)::Vector{LanguageNode}
    ancestors = LanguageNode[]

    function find_path(current::LanguageNode, target_id::String, path::Vector{LanguageNode})::Bool
        push!(path, current)

        if current.id == target_id
            return true
        end

        for child in current.children
            if find_path(child, target_id, path)
                return true
            end
        end

        pop!(path)
        return false
    end

    find_path(tree.root, node_id, ancestors)
    return ancestors
end

"""
    get_subtree(tree::LanguageTree, node_id::String) -> Union{LanguageNode, Nothing}

Get a subtree rooted at the given node.
"""
function get_subtree(tree::LanguageTree, node_id::String)::Union{LanguageNode, Nothing}
    return get(tree.index, node_id, nothing)
end

"""
    get_locale_family(tree::LanguageTree, locale::String) -> String

Get the language family for a locale code (e.g., "en" -> "Indo-European").
"""
function get_locale_family(tree::LanguageTree, locale::String)::String
    # Extract language from locale (e.g., "en-US" -> "en")
    lang = split(locale, "-")[1]

    # Map common 2-letter codes to ISO 639-3
    iso_map = Dict(
        "en" => "eng", "de" => "deu", "fr" => "fra", "es" => "spa",
        "it" => "ita", "pt" => "por", "nl" => "nld", "ru" => "rus",
        "pl" => "pol", "uk" => "ukr", "cs" => "ces", "sk" => "slk",
        "ja" => "jpn", "ko" => "kor", "zh" => "cmn", "ar" => "ara",
        "he" => "heb", "hi" => "hin", "bn" => "ben", "ta" => "tam",
        "th" => "tha", "vi" => "vie", "id" => "ind", "ms" => "msa",
        "tr" => "tur", "el" => "ell", "sv" => "swe", "da" => "dan",
        "no" => "nor", "fi" => "fin", "hu" => "hun", "ro" => "ron"
    )

    iso = get(iso_map, lang, lang)

    if haskey(tree.by_iso, iso)
        ancestors = get_ancestors(tree, tree.by_iso[iso].id)
        if length(ancestors) >= 2
            return ancestors[2].name  # First level after root
        end
    end

    return "Unknown"
end

"""
    suggest_fallback_locales(tree::LanguageTree, locale::String, max_suggestions::Int=5) -> Vector{String}

Suggest fallback locales based on language family relationships.
"""
function suggest_fallback_locales(tree::LanguageTree, locale::String, max_suggestions::Int=5)::Vector{String}
    lang = split(locale, "-")[1]

    iso_map = Dict(
        "en" => "eng", "de" => "deu", "fr" => "fra", "es" => "spa",
        "it" => "ita", "pt" => "por", "nl" => "nld", "ru" => "rus"
    )
    reverse_map = Dict(v => k for (k, v) in iso_map)

    iso = get(iso_map, lang, lang)

    if !haskey(tree.by_iso, iso)
        return String[]
    end

    # Get ancestors and find siblings at each level
    node = tree.by_iso[iso]
    ancestors = get_ancestors(tree, node.id)

    suggestions = String[]

    # Go up the tree, collecting related languages
    for i in length(ancestors):-1:1
        ancestor = ancestors[i]
        for child in ancestor.children
            collect_languages!(suggestions, child, reverse_map)
            if length(suggestions) >= max_suggestions
                break
            end
        end
        if length(suggestions) >= max_suggestions
            break
        end
    end

    # Filter out the original locale
    filter!(s -> s != lang, suggestions)

    return suggestions[1:min(length(suggestions), max_suggestions)]
end

function collect_languages!(result::Vector{String}, node::LanguageNode, iso_map::Dict)
    if !isnothing(node.iso639_3) && haskey(iso_map, node.iso639_3)
        push!(result, iso_map[node.iso639_3])
    end
    for child in node.children
        collect_languages!(result, child, iso_map)
    end
end

# === Visualization Functions ===

"""
    plot_tree(tree::LanguageTree; max_depth=3) -> Figure

Plot the language tree as a cladogram using Makie.
"""
function plot_tree(tree::LanguageTree; max_depth::Int=3, width::Int=1200, height::Int=800)
    fig = Figure(size=(width, height))
    ax = Axis(fig[1, 1], title=tree.root.name)

    # Build graph
    g = SimpleDiGraph()
    labels = String[]
    colors = RGBA{Float64}[]

    node_map = Dict{String, Int}()

    function add_node!(node::LanguageNode, depth::Int)
        if depth > max_depth
            return nothing
        end

        idx = nv(g) + 1
        add_vertex!(g)
        node_map[node.id] = idx

        # Color by level
        color = if node.level == "family"
            RGBA(0.2, 0.4, 0.8, 1.0)
        elseif node.level == "language"
            RGBA(0.2, 0.7, 0.3, 1.0)
        else
            RGBA(0.7, 0.7, 0.7, 1.0)
        end

        push!(labels, node.name)
        push!(colors, color)

        return idx
    end

    function traverse!(node::LanguageNode, depth::Int)
        parent_idx = add_node!(node, depth)
        if isnothing(parent_idx)
            return
        end

        for child in node.children
            child_idx = add_node!(child, depth + 1)
            if !isnothing(child_idx)
                add_edge!(g, parent_idx, child_idx)
                traverse!(child, depth + 1)
            end
        end
    end

    traverse!(tree.root, 1)

    # Plot using GraphMakie
    graphplot!(ax, g,
        layout=Buchheim(),
        nlabels=labels,
        node_color=colors,
        node_size=20,
        edge_color=:gray,
        nlabels_fontsize=10
    )

    hidedecorations!(ax)
    hidespines!(ax)

    return fig
end

"""
    plot_subtree(tree::LanguageTree, node_id::String; max_depth=4) -> Figure

Plot a subtree as a cladogram.
"""
function plot_subtree(tree::LanguageTree, node_id::String; max_depth::Int=4, kwargs...)
    subtree_root = get_subtree(tree, node_id)
    if isnothing(subtree_root)
        error("Node not found: $node_id")
    end

    subtree = build_tree(subtree_root)
    return plot_tree(subtree; max_depth=max_depth, kwargs...)
end

"""
    export_svg(fig::Figure, path::String)

Export a figure to SVG format.
"""
function export_svg(fig::Figure, path::String)
    save(path, fig)
end

# === Prebuilt Trees ===

"""
    create_indo_european_sample() -> LanguageTree

Create a sample Indo-European tree for testing.
"""
function create_indo_european_sample()::LanguageTree
    # Build a simplified Indo-European tree
    romance = LanguageNode("roma1334", "Romance", nothing, "family", [
        LanguageNode("stan1288", "Spanish", "spa", "language", []),
        LanguageNode("stan1289", "French", "fra", "language", []),
        LanguageNode("stan1290", "Italian", "ita", "language", []),
        LanguageNode("stan1291", "Portuguese", "por", "language", []),
        LanguageNode("roma1327", "Romanian", "ron", "language", []),
    ])

    germanic = LanguageNode("germ1287", "Germanic", nothing, "family", [
        LanguageNode("stan1293", "English", "eng", "language", []),
        LanguageNode("stan1295", "German", "deu", "language", []),
        LanguageNode("dutc1256", "Dutch", "nld", "language", []),
        LanguageNode("swed1254", "Swedish", "swe", "language", []),
        LanguageNode("dani1285", "Danish", "dan", "language", []),
        LanguageNode("norw1258", "Norwegian", "nor", "language", []),
    ])

    slavic = LanguageNode("slav1255", "Slavic", nothing, "family", [
        LanguageNode("russ1263", "Russian", "rus", "language", []),
        LanguageNode("poli1260", "Polish", "pol", "language", []),
        LanguageNode("ukra1253", "Ukrainian", "ukr", "language", []),
        LanguageNode("czec1258", "Czech", "ces", "language", []),
        LanguageNode("bulg1262", "Bulgarian", "bul", "language", []),
    ])

    indo_iranian = LanguageNode("indo1321", "Indo-Iranian", nothing, "family", [
        LanguageNode("hind1269", "Hindi", "hin", "language", []),
        LanguageNode("beng1280", "Bengali", "ben", "language", []),
        LanguageNode("punj1256", "Punjabi", "pan", "language", []),
        LanguageNode("fars1254", "Persian", "fas", "language", []),
    ])

    root = LanguageNode(INDO_EUROPEAN, "Indo-European", nothing, "family", [
        romance, germanic, slavic, indo_iranian
    ])

    return build_tree(root)
end

end # module
