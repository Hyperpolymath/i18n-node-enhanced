-------------------------------------------------------------------------------
--  Polyglot_TUI.Terminal
--
--  Terminal abstraction layer for the TUI.
--  Provides platform-independent terminal I/O.
-------------------------------------------------------------------------------

with Polyglot_TUI.Types; use Polyglot_TUI.Types;

package Polyglot_TUI.Terminal is

   --  Terminal dimensions
   type Dimensions is record
      Width  : Positive := 80;
      Height : Positive := 24;
   end record;

   --  Colors (256-color palette indices)
   type Color is range 0 .. 255;

   --  Standard colors
   Color_Default    : constant Color := 0;
   Color_Black      : constant Color := 0;
   Color_Red        : constant Color := 1;
   Color_Green      : constant Color := 2;
   Color_Yellow     : constant Color := 3;
   Color_Blue       : constant Color := 4;
   Color_Magenta    : constant Color := 5;
   Color_Cyan       : constant Color := 6;
   Color_White      : constant Color := 7;

   --  Text attributes
   type Attribute is (Bold, Dim, Italic, Underline, Blink, Reverse, Hidden);
   type Attribute_Set is array (Attribute) of Boolean;

   No_Attributes : constant Attribute_Set := (others => False);

   --  Cell style
   type Style is record
      Foreground : Color := Color_Default;
      Background : Color := Color_Default;
      Attributes : Attribute_Set := No_Attributes;
   end record;

   Default_Style : constant Style :=
      (Foreground => Color_Default,
       Background => Color_Default,
       Attributes => No_Attributes);

   --  Key input
   type Key_Code is
      (Key_None,
       Key_Escape,
       Key_Enter,
       Key_Tab,
       Key_Backspace,
       Key_Delete,
       Key_Insert,
       Key_Home,
       Key_End,
       Key_Page_Up,
       Key_Page_Down,
       Key_Up,
       Key_Down,
       Key_Left,
       Key_Right,
       Key_F1, Key_F2, Key_F3, Key_F4, Key_F5, Key_F6,
       Key_F7, Key_F8, Key_F9, Key_F10, Key_F11, Key_F12,
       Key_Char);  -- Regular character input

   type Key_Event is record
      Code      : Key_Code := Key_None;
      Character : Character := ' ';
      Alt       : Boolean := False;
      Ctrl      : Boolean := False;
      Shift     : Boolean := False;
   end record;

   --  Terminal operations
   procedure Initialize;
   procedure Shutdown;

   function Get_Dimensions return Dimensions;

   procedure Clear;
   procedure Clear_Line (Row : Positive);

   procedure Move_Cursor (Row, Column : Positive);
   procedure Hide_Cursor;
   procedure Show_Cursor;

   procedure Set_Style (S : Style);
   procedure Reset_Style;

   procedure Put (C : Character);
   procedure Put (S : String);
   procedure Put_Line (S : String);

   procedure Put_At (Row, Column : Positive; S : String);
   procedure Put_At (Row, Column : Positive; S : String; St : Style);

   procedure Refresh;

   function Poll_Key (Timeout_Ms : Natural := 0) return Key_Event;
   function Wait_Key return Key_Event;

   --  Box drawing
   type Box_Style is (Single, Double, Rounded, Heavy, ASCII_Only);

   procedure Draw_Box
      (Row, Column : Positive;
       Width, Height : Positive;
       Style : Box_Style := Single;
       Title : String := "");

   procedure Draw_Horizontal_Line
      (Row, Column : Positive;
       Width : Positive;
       Style : Box_Style := Single);

   procedure Draw_Vertical_Line
      (Row, Column : Positive;
       Height : Positive;
       Style : Box_Style := Single);

end Polyglot_TUI.Terminal;
