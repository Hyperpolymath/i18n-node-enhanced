-------------------------------------------------------------------------------
--  Polyglot_TUI.Main
--
--  Entry point for the Polyglot TUI application.
-------------------------------------------------------------------------------

with Ada.Command_Line;
with Ada.Text_IO;
with Ada.Exceptions;

with Polyglot_TUI.App;
with Polyglot_TUI.Terminal;
with Polyglot_TUI.Types;

procedure Polyglot_TUI.Main is
   use Ada.Text_IO;
   use Polyglot_TUI.App;
   use Polyglot_TUI.Types;

   App : Application;

   procedure Print_Usage is
   begin
      Put_Line ("Usage: polyglot-tui [OPTIONS] [DIRECTORY]");
      New_Line;
      Put_Line ("A terminal interface for managing i18n translations.");
      New_Line;
      Put_Line ("Options:");
      Put_Line ("  -h, --help     Show this help message");
      Put_Line ("  -v, --version  Show version information");
      Put_Line ("  -l, --locale   Set initial locale");
      Put_Line ("  -c, --config   Path to configuration file");
      New_Line;
      Put_Line ("Navigation:");
      Put_Line ("  j/k or ↑/↓    Move cursor up/down");
      Put_Line ("  h/l or ←/→    Move cursor left/right");
      Put_Line ("  g/G           Go to top/bottom");
      Put_Line ("  /             Search");
      Put_Line ("  Enter         Edit selected translation");
      Put_Line ("  Tab           Switch locale");
      Put_Line ("  q             Quit");
      New_Line;
      Put_Line ("Views:");
      Put_Line ("  1             Catalog browser");
      Put_Line ("  2             Statistics");
      Put_Line ("  3             Diff view");
      Put_Line ("  ?             Help");
   end Print_Usage;

   procedure Print_Version is
   begin
      Put_Line ("polyglot-tui " & Polyglot_TUI.Version_String);
      Put_Line ("Part of polyglot-i18n - ReScript-first i18n for Deno");
      Put_Line ("Built with Ada/SPARK for formal verification");
   end Print_Version;

   procedure Parse_Arguments is
      use Ada.Command_Line;
   begin
      for I in 1 .. Argument_Count loop
         declare
            Arg : constant String := Argument (I);
         begin
            if Arg = "-h" or Arg = "--help" then
               Print_Usage;
               return;
            elsif Arg = "-v" or Arg = "--version" then
               Print_Version;
               return;
            end if;
         end;
      end loop;
   end Parse_Arguments;

begin
   --  Parse command line arguments
   Parse_Arguments;

   --  Initialize terminal
   Terminal.Initialize;

   --  Initialize and run application
   begin
      Initialize (App);

      --  Main loop
      Run (App);

   exception
      when E : others =>
         Terminal.Shutdown;
         Put_Line (Standard_Error,
            "Error: " & Ada.Exceptions.Exception_Message (E));
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end;

   --  Cleanup
   Shutdown (App);
   Terminal.Shutdown;

exception
   when E : others =>
      --  Ensure terminal is restored on any error
      begin
         Terminal.Shutdown;
      exception
         when others => null;
      end;
      Put_Line (Standard_Error,
         "Fatal error: " & Ada.Exceptions.Exception_Message (E));
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
end Polyglot_TUI.Main;
