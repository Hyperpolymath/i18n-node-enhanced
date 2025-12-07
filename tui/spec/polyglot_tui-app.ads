-------------------------------------------------------------------------------
--  Polyglot_TUI.App
--
--  Main application controller for the TUI.
--  Manages views, state, and user interaction.
-------------------------------------------------------------------------------

with Polyglot_TUI.Types;    use Polyglot_TUI.Types;
with Polyglot_TUI.Terminal; use Polyglot_TUI.Terminal;
with Polyglot_TUI.Catalog;  use Polyglot_TUI.Catalog;

package Polyglot_TUI.App is

   --  Application state
   type App_State is record
      Current_View     : View_Mode := Catalog_Browser;
      Previous_View    : View_Mode := Catalog_Browser;
      Active_Locale    : Locale_String := Empty_Locale;
      Selected_Key     : Key_String := Empty_Key;
      Cursor           : Cursor_Position := (Row => 1, Column => 1);
      Scroll_Offset    : Natural := 0;
      Search_Query     : Key_String := Empty_Key;
      Is_Running       : Boolean := True;
      Has_Unsaved      : Boolean := False;
      Status_Message   : String (1 .. 80) := (others => ' ');
      Status_Length    : Natural := 0;
   end record;

   --  Application instance
   type Application is limited private;
   type Application_Access is access all Application;

   --  Lifecycle
   procedure Initialize (App : out Application);
   procedure Run (App : in out Application);
   procedure Shutdown (App : in out Application);

   --  State access
   function Get_State (App : Application) return App_State;
   function Is_Running (App : Application) return Boolean;

   --  View management
   procedure Switch_View (App : in out Application; View : View_Mode);
   procedure Go_Back (App : in out Application);

   --  Catalog management
   procedure Load_Catalog
      (App    : in out Application;
       Locale : Locale_String;
       Path   : String);

   procedure Save_Catalog
      (App    : in out Application;
       Locale : Locale_String;
       Path   : String);

   procedure Set_Active_Locale
      (App    : in out Application;
       Locale : Locale_String);

   --  Navigation
   procedure Move_Up (App : in out Application);
   procedure Move_Down (App : in Out Application);
   procedure Move_Left (App : in out Application);
   procedure Move_Right (App : in Out Application);
   procedure Page_Up (App : in Out Application);
   procedure Page_Down (App : in Out Application);
   procedure Go_To_Top (App : in Out Application);
   procedure Go_To_Bottom (App : in Out Application);

   --  Actions
   procedure Select_Item (App : in Out Application);
   procedure Delete_Item (App : in out Application);
   procedure Search (App : in out Application; Query : String);
   procedure Clear_Search (App : in out Application);

   --  Status
   procedure Set_Status (App : in out Application; Message : String);
   procedure Clear_Status (App : in out Application);

private

   type Locale_Index is range 0 .. Max_Locales;
   type Catalog_Array is array (1 .. Max_Locales) of Catalog;

   type Application is limited record
      State        : App_State;
      Catalogs     : Catalog_Array;
      Locale_Count : Locale_Index := 0;
      Term_Size    : Dimensions := (Width => 80, Height => 24);
   end record;

end Polyglot_TUI.App;
