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
                   not Has_Key (Cat, Key);

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
