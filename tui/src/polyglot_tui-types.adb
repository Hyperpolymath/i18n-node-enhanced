-------------------------------------------------------------------------------
--  Polyglot_TUI.Types (body)
--
--  Implementation of utility functions for bounded string types.
-------------------------------------------------------------------------------

pragma SPARK_Mode (On);

package body Polyglot_TUI.Types is

   function To_Locale_String (S : String) return Locale_String is
      Result : Locale_String := Empty_Locale;
   begin
      Result.Length := S'Length;
      Result.Data (1 .. S'Length) := S;
      return Result;
   end To_Locale_String;

   function To_Key_String (S : String) return Key_String is
      Result : Key_String := Empty_Key;
   begin
      Result.Length := S'Length;
      Result.Data (1 .. S'Length) := S;
      return Result;
   end To_Key_String;

   function To_Translation_String (S : String) return Translation_String is
      Result : Translation_String := Empty_Translation;
   begin
      Result.Length := S'Length;
      Result.Data (1 .. S'Length) := S;
      return Result;
   end To_Translation_String;

   function From_Locale_String (L : Locale_String) return String is
   begin
      return L.Data (1 .. L.Length);
   end From_Locale_String;

   function From_Key_String (K : Key_String) return String is
   begin
      return K.Data (1 .. K.Length);
   end From_Key_String;

   function From_Translation_String (T : Translation_String) return String is
   begin
      return T.Data (1 .. T.Length);
   end From_Translation_String;

end Polyglot_TUI.Types;
