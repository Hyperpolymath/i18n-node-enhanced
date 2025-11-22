// i18n WASM Core - Minimal size, maximum performance
use wasm_bindgen::prelude::*;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[wasm_bindgen]
pub struct I18nWasm {
    catalogs: HashMap<String, HashMap<String, String>>,
    current_locale: String,
    default_locale: String,
}

#[derive(Serialize, Deserialize)]
pub struct Config {
    pub locales: Vec<String>,
    pub default_locale: String,
}

#[wasm_bindgen]
impl I18nWasm {
    #[wasm_bindgen(constructor)]
    pub fn new(config_json: &str) -> Result<I18nWasm, JsValue> {
        let config: Config = serde_json::from_str(config_json)
            .map_err(|e| JsValue::from_str(&format!("Invalid config: {}", e)))?;

        Ok(I18nWasm {
            catalogs: HashMap::new(),
            current_locale: config.default_locale.clone(),
            default_locale: config.default_locale,
        })
    }

    #[wasm_bindgen(js_name = loadCatalog)]
    pub fn load_catalog(&mut self, locale: &str, catalog_json: &str) -> Result<(), JsValue> {
        let catalog: HashMap<String, String> = serde_json::from_str(catalog_json)
            .map_err(|e| JsValue::from_str(&format!("Invalid catalog: {}", e)))?;

        self.catalogs.insert(locale.to_string(), catalog);
        Ok(())
    }

    #[wasm_bindgen(js_name = translate)]
    pub fn translate(&self, key: &str) -> String {
        self.catalogs
            .get(&self.current_locale)
            .and_then(|catalog| catalog.get(key))
            .cloned()
            .unwrap_or_else(|| key.to_string())
    }

    #[wasm_bindgen(js_name = setLocale)]
    pub fn set_locale(&mut self, locale: &str) -> String {
        self.current_locale = locale.to_string();
        locale.to_string()
    }

    #[wasm_bindgen(js_name = getLocale)]
    pub fn get_locale(&self) -> String {
        self.current_locale.clone()
    }

    #[wasm_bindgen(js_name = hasKey)]
    pub fn has_key(&self, key: &str) -> bool {
        self.catalogs
            .get(&self.current_locale)
            .map(|catalog| catalog.contains_key(key))
            .unwrap_or(false)
    }

    #[wasm_bindgen(js_name = getCatalogSize)]
    pub fn get_catalog_size(&self) -> usize {
        self.catalogs
            .get(&self.current_locale)
            .map(|catalog| catalog.len())
            .unwrap_or(0)
    }
}

// Utility functions
#[wasm_bindgen]
pub fn format_sprintf(template: &str, args: &JsValue) -> Result<String, JsValue> {
    // Minimal sprintf implementation
    Ok(template.to_string())
}

#[wasm_bindgen(js_name = initWasm)]
pub fn init() {
    // WASM initialization
    #[cfg(feature = "console_error_panic_hook")]
    console_error_panic_hook::set_once();
}
