-------------------------------------------------------------------------------
--  Polyglot_TUI.Types
--
--  Core types for the Polyglot TUI application.
--  This package is in SPARK for formal verification.
-------------------------------------------------------------------------------

pragma SPARK_Mode (On);

package Polyglot_TUI.Types is

   --  Maximum sizes for bounded types
   Max_Locale_Length      : constant := 35;   -- e.g., "zh-Hans-CN-variant"
   Max_Key_Length         : constant := 256;
   Max_Translation_Length : constant := 4096;
   Max_Locales            : constant := 100;
   Max_Keys               : constant := 10000;

   --  Bounded string types
   subtype Locale_Length is Natural range 0 .. Max_Locale_Length;
   subtype Key_Length is Natural range 0 .. Max_Key_Length;
   subtype Translation_Length is Natural range 0 .. Max_Translation_Length;

   type Locale_String is record
      Data   : String (1 .. Max_Locale_Length);
      Length : Locale_Length;
   end record;

   type Key_String is record
      Data   : String (1 .. Max_Key_Length);
      Length : Key_Length;
   end record;

   type Translation_String is record
      Data   : String (1 .. Max_Translation_Length);
      Length : Translation_Length;
   end record;

   --  Plural categories (CLDR)
   type Plural_Category is (Zero, One, Two, Few, Many, Other);

   --  Translation entry with plural support
   type Plural_Forms is record
      Zero_Form   : Translation_String;
      One_Form    : Translation_String;
      Two_Form    : Translation_String;
      Few_Form    : Translation_String;
      Many_Form   : Translation_String;
      Other_Form  : Translation_String;
      Has_Zero    : Boolean := False;
      Has_One     : Boolean := False;
      Has_Two     : Boolean := False;
      Has_Few     : Boolean := False;
      Has_Many    : Boolean := False;
   end record;

   type Translation_Kind is (Simple, Plural);

   type Translation_Entry (Kind : Translation_Kind := Simple) is record
      case Kind is
         when Simple =>
            Value : Translation_String;
         when Plural =>
            Forms : Plural_Forms;
      end case;
   end record;

   --  TUI view modes
   type View_Mode is
      (Catalog_Browser,    -- Browse translation keys
       Translation_Editor, -- Edit a translation
       Locale_Selector,    -- Select active locale
       Search_View,        -- Search translations
       Diff_View,          -- Compare locales
       Statistics_View,    -- Coverage statistics
       Help_View);         -- Help screen

   --  TUI state
   type Cursor_Position is record
      Row    : Positive := 1;
      Column : Positive := 1;
   end record;

   --  Empty string constants
   Empty_Locale : constant Locale_String :=
      (Data => (others => ' '), Length => 0);

   Empty_Key : constant Key_String :=
      (Data => (others => ' '), Length => 0);

   Empty_Translation : constant Translation_String :=
      (Data => (others => ' '), Length => 0);

   --  Utility functions
   function To_Locale_String (S : String) return Locale_String
      with Pre => S'Length <= Max_Locale_Length;

   function To_Key_String (S : String) return Key_String
      with Pre => S'Length <= Max_Key_Length;

   function To_Translation_String (S : String) return Translation_String
      with Pre => S'Length <= Max_Translation_Length;

   function From_Locale_String (L : Locale_String) return String
      with Post => From_Locale_String'Result'Length = L.Length;

   function From_Key_String (K : Key_String) return String
      with Post => From_Key_String'Result'Length = K.Length;

   function From_Translation_String (T : Translation_String) return String
      with Post => From_Translation_String'Result'Length = T.Length;

end Polyglot_TUI.Types;
