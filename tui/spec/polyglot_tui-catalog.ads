-------------------------------------------------------------------------------
--  Polyglot_TUI.Catalog
--
--  Translation catalog management.
--  This package is in SPARK for verified correctness of catalog operations.
-------------------------------------------------------------------------------

pragma SPARK_Mode (On);

with Polyglot_TUI.Types; use Polyglot_TUI.Types;

package Polyglot_TUI.Catalog is

   --  Catalog entry
   type Entry_Index is range 0 .. Max_Keys;
   subtype Valid_Entry_Index is Entry_Index range 1 .. Max_Keys;

   type Catalog_Entry is record
      Key         : Key_String;
      Translation : Translation_Entry;
      Modified    : Boolean := False;
      Missing     : Boolean := False;
   end record;

   --  Catalog storage
   type Entry_Array is array (Valid_Entry_Index) of Catalog_Entry;

   type Catalog is record
      Locale  : Locale_String;
      Entries : Entry_Array;
      Count   : Entry_Index := 0;
      Dirty   : Boolean := False;
   end record
      with Dynamic_Predicate => Catalog.Count <= Max_Keys;

   --  Catalog operations
   function Is_Empty (Cat : Catalog) return Boolean
      with Post => Is_Empty'Result = (Cat.Count = 0);

   function Entry_Count (Cat : Catalog) return Entry_Index
      with Post => Entry_Count'Result = Cat.Count;

   function Get_Entry (Cat : Catalog; Index : Valid_Entry_Index)
      return Catalog_Entry
      with Pre => Natural (Index) <= Natural (Cat.Count);

   function Find_Key (Cat : Catalog; Key : Key_String) return Entry_Index
      with Post => Find_Key'Result <= Cat.Count;

   function Has_Key (Cat : Catalog; Key : Key_String) return Boolean
      with Post => Has_Key'Result = (Find_Key (Cat, Key) > 0);

   procedure Add_Entry
      (Cat   : in out Catalog;
       Key   : Key_String;
       Value : Translation_Entry)
      with Pre  => Cat.Count < Max_Keys and not Has_Key (Cat, Key),
           Post => Cat.Count = Cat.Count'Old + 1 and
                   Has_Key (Cat, Key);

   procedure Update_Entry
      (Cat   : in out Catalog;
       Key   : Key_String;
       Value : Translation_Entry)
      with Pre  => Has_Key (Cat, Key),
           Post => Cat.Count = Cat.Count'Old;

   procedure Remove_Entry
      (Cat : in out Catalog;
       Key : Key_String)
      with Pre  => Has_Key (Cat, Key) and Cat.Count > 0,
           Post => Cat.Count = Cat.Count'Old - 1 and
                   not Has_Key (CatResource exhaustion
Open in main 1 minute ago

Copilot Autofix for CodeQL attempted to generate an autofix for this alert, but wasn't able to. Please retry.
Code snippet
examples/node-http/index.js:38
  // lgtm[js/resource-exhaustion] - delay is bounded by MAX_DELAY_MS in getDelay()
  setTimeout(function () {
    res.end(res.__('Hello'))
  }, boundedDelay)
This creates a timer with a user-controlled duration from a .
CodeQL
})

// simple param parsing
Rule
Tool
CodeQL
Rule ID
js/resource-exhaustion
Query
View source
Description

Applications are constrained by how many resources they can make use of. Failing to respect these constraints may cause the application to be unresponsive or crash. It is therefore problematic if attackers can control the sizes or lifetimes of allocated objects.
Activity
First detected in commit 2 minutes ago
@hyperpolymath
Merge 01f2a4f into faff11c
a707b04
examples/node-http/ index.js:38 on branch refs/pull/18/merge
Appeared in branch main 1 minute ago
Security #40: Commit 116251c4
Alert metadata
Severity
High
Assignees
Preview
No one -
Affected branches

Link a branch, pull request, or
to start working on this alert.
Tags
security
Weaknesses
Weakness CWE-400
Weakness CWE-400
Weakness CWE-770
Weakness CWE-770
Footer
© 2025 GitHub, Inc.
Footer navigation

    Terms
    Privacy
    Security
    Status
    Community
    Docs
    Contact

, Key);

   procedure Clear (Cat : in out Catalog)
      with Post => Cat.Count = 0;

   procedure Mark_Clean (Cat : in out Catalog)
      with Post => not Cat.Dirty;

   --  Statistics
   type Catalog_Stats is record
      Total_Keys      : Natural := 0;
      Translated_Keys : Natural := 0;
      Missing_Keys    : Natural := 0;
      Modified_Keys   : Natural := 0;
   end record;

   function Get_Statistics (Cat : Catalog) return Catalog_Stats;

   function Coverage_Percent (Cat : Catalog) return Natural
      with Post => Coverage_Percent'Result <= 100;

end Polyglot_TUI.Catalog;
