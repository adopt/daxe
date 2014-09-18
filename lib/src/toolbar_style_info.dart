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

class ToolbarStyleInfo {
  List<x.Element> possibleRefs; /* list of possible element references for the toolbar item */
  x.Element validRef; /* one of possibleRefs, which can be used now */
  String cssName;
  String cssValue;
  
  ToolbarStyleInfo(this.possibleRefs, this.cssName, this.cssValue) {
    assert(possibleRefs != null && possibleRefs.length > 0 &&
        (cssName == null || cssValue != null));
    validRef = null;
  }
  
  String get css {
    if (cssName == null)
      return(null);
    return("$cssName: $cssValue");
  }
  
  bool findValidRef(List<x.Element> list) {
    for (x.Element possibleRef in possibleRefs) {
      if (list.contains(possibleRef)) {
        validRef = possibleRef;
        return(true);
      }
    }
    validRef = null;
    return(false);
  }
}
