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

part of daxe;

class DaxeException implements Exception {
  final String message;
  final Exception parentException;
  
  const DaxeException([this.message, this.parentException]);
  
  String toString() {
    String s;
    if (message == null)
      s = 'DaxeException';
    else
      s = message;
    if (parentException != null)
      s = "$s (parent exception: $parentException)";
    return(s);
  }
  
}

