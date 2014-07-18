/*
  This file is part of Daxe.

  Daxe is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Daxe is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Daxe.  If not, see <http://www.gnu.org/licenses/>.
*/

/**
 * Daxe - Dart XML Editor
 * The goal of this project is to replace the Jaxe Java applet in WebJaxe, but Daxe
 * could be used to edit XML documents online in any other application.
 * 
 * The URL must have the file and config parameters with the path to the XML file and Jaxe config file.
 * It can also have a save parameter with the path to a server script to save the document.
 */
import 'package:daxe/daxe.dart' as d;


void main() {
  // custom display types and functions could be added here in another application
  d.main();
}
