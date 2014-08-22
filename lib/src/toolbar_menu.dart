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

typedef void UpdateMenuState(ToolbarMenu tbmenu, DaxeNode parent, DaxeNode selectedNode,
                               List<x.Element> validRefs, List<x.Element> ancestorRefs);

class ToolbarMenu extends ToolbarItem {
  Menu menu;
  String title;
  UpdateMenuState update;
  
  ToolbarMenu(this.menu, this.update) {
    title = menu.title;
  }
  
  h.Element html() {
    h.DivElement div = new h.DivElement();
    div.classes.add('toolbar-menu');
    div.append(page.mbar.createMenuDiv(menu));
    return(div);
  }
}
