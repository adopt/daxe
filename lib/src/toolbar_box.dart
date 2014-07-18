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

class ToolbarBox extends ToolbarItem {
  List<ToolbarButton> buttons;
  
  ToolbarBox() {
    buttons = new List<ToolbarButton>();
  }
  
  add(ToolbarButton button) {
    buttons.add(button);
  }
  
  insert(ToolbarButton button, int position) {
    buttons.insert(position, button);
  }
  
  remove(int position) {
    buttons.remove(position);
  }
  
  get length {
    return(buttons.length);
  }
  
  h.Element html() {
    h.DivElement div = new h.DivElement();
    div.classes.add('toolbar-box');
    for (ToolbarButton button in buttons) {
      div.append(button.html());
    }
    return(div);
  }
}
