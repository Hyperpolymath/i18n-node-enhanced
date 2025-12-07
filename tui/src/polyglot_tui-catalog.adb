-------------------------------------------------------------------------------
--  Polyglot_TUI.Catalog (body)
--
--  Implementation of catalog operations with SPARK verification.
-------------------------------------------------------------------------------

pragma SPARK_Mode (On);

package body Polyglot_TUI.Catalog is

   function Is_Empty (Cat : Catalog) return Boolean is
   begin
      return Cat.Count = 0;
   end Is_Empty;

   function Entry_Count (Cat : Catalog) return Entry_Index is
   begin
      return Cat.Count;
   end Entry_Count;

   function Get_Entry (Cat : Catalog; Index : Valid_Entry_Index)
      return Catalog_Entry is
   begin
      return Cat.Entries (Index);
   end Get_Entry;

   function Keys_Equal (A, B : Key_String) return Boolean is
   begin
      if A.Length /= B.Length then
         return False;
      end if;
      return A.Data (1 .. A.Length) = B.Data (1 .. B.Length);
   end Keys_Equal;

   function Find_Key (Cat : Catalog; Key : Key_String) return Entry_Index is
   begin
      for I in 1 .. Cat.Count loop
         if Keys_Equal (Cat.Entries (Valid_Entry_Index (I)).Key, Key) then
            return I;
         end if;
      end loop;
      return 0;
   end Find_Key;

   function Has_Key (Cat : Catalog; Key : Key_String) return Boolean is
   begin
      return Find_Key (Cat, Key) > 0;
   end Has_Key;

   procedure Add_Entry
      (Cat   : in out Catalog;
       Key   : Key_String;
       Value : Translation_Entry) is
      New_Index : constant Valid_Entry_Index :=
         Valid_Entry_Index (Cat.Count + 1);
   begin
      Cat.Entries (New_Index) :=
         (Key         => Key,
          Translation => Value,
          Modified    => True,
          Missing     => False);
      Cat.Count := Cat.Count + 1;
      Cat.Dirty := True;
   end Add_Entry;

   procedure Update_Entry
      (Cat   : in Out Catalog;
       Key   : Key_String;
       Value : Translation_Entry)
   is
      Index : constant Entry_Index := Find_Key (Cat, Key);
   begin
      if Index > 0 then
         Cat.Entries (Valid_Entry_Index (Index)).Translation := Value;
         Cat.Entries (Valid_Entry_Index (Index)).Modified := True;
         Cat.Dirty := True;
      end if;
   end Update_Entry;

   procedure Remove_Entry
      (Cat : in Out Catalog;
       Key : Key_String)
   is
      Index : constant Entry_Index := Find_Key (Cat, Key);
   begin
      if Index > 0 and Index < Cat.Count then
         --  Shift entries down
         for I in Valid_Entry_Index (Index) .. Valid_Entry_Index (Cat.Count - 1) loop
            Cat.Entries (I) := Cat.Entries (I + 1);
         end loop;
      end if;
      Cat.Count := Cat.Count - 1;
      Cat.Dirty := True;
   end Remove_Entry;

   procedure Clear (Cat : in Out Catalog) is
   begin
      Cat.Count := 0;
      Cat.Dirty := True;
   end Clear;

   procedure Mark_Clean (Cat : in Out Catalog) is
   begin
      Cat.Dirty := False;
      for I in 1 .. Cat.Count loop
         Cat.Entries (Valid_Entry_Index (I)).Modified := False;
      end loop;
   end Mark_Clean;

   function Get_Statistics (Cat : Catalog) return Catalog_Stats is
      Stats : Catalog_Stats := (others => 0);
   begin
      Stats.Total_Keys := Natural (Cat.Count);

      for I in 1 .. Cat.Count loop
         declare
            E : constant Catalog_Entry :=
               Cat.Entries (Valid_Entry_Index (I));
         begin
            if E.Missing then
               Stats.Missing_Keys := Stats.Missing_Keys + 1;
            else
               Stats.Translated_Keys := Stats.Translated_Keys + 1;
            end if;

            if E.Modified then
               Stats.Modified_Keys := Stats.Modified_Keys + 1;
            end if;
         end;
      end loop;

      return Stats;
   end Get_Statistics;

   function Coverage_Percent (Cat : Catalog) return Natural is
      Stats : constant Catalog_Stats := Get_Statistics (Cat);
   begin
      if Stats.Total_Keys = 0 then
         return 100;
      end if;
      return (Stats.Translated_Keys * 100) / Stats.Total_Keys;
   end Coverage_Percent;

end Polyglot_TUI.Catalog;
