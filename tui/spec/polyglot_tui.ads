-------------------------------------------------------------------------------
--  Polyglot_TUI
--
--  Root package for the Polyglot translation management TUI.
--  Provides a terminal-based interface for managing i18n translations.
--
--  Architecture:
--    - SPARK core for verified correctness
--    - ncurses/termbox bindings for terminal I/O
--    - IPC with Deno/ReScript backend
-------------------------------------------------------------------------------

package Polyglot_TUI is

   pragma Pure;

   --  Version information
   Version_Major : constant := 2;
   Version_Minor : constant := 0;
   Version_Patch : constant := 0;
   Version_String : constant String := "2.0.0-alpha";

   --  Application name
   App_Name : constant String := "polyglot-tui";

end Polyglot_TUI;
