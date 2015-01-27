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

typedef void UpdateButtonState(ToolbarButton button, DaxeNode parent, DaxeNode selectedNode,
                               List<x.Element> validRefs, List<x.Element> ancestorRefs);

class ToolbarButton {
  static int idcount = 0;
  String _title;
  String iconFilename;
  ActionFunction action;
  UpdateButtonState update;
  Object data;
  String id;
  bool enabled;
  bool selected;
  StreamSubscription<h.MouseEvent> listener;
  String shortcut;
  int iconWidth;
  int iconHeight;
  
  ToolbarButton(this._title, this.iconFilename, this.action, this.update,
      {this.data, this.enabled:true, this.shortcut, this.iconWidth:16, this.iconHeight:16}) {
    selected = false;
    id = "button_$idcount";
    idcount++;
  }
  
  h.Element html() {
    h.DivElement div = new h.DivElement();
    div.id = id;
    div.classes.add('toolbar-button');
    if (!enabled)
      div.classes.add('button-disabled');
    if (selected)
      div.classes.add('button-selected');
    div.setAttribute('tabindex', '-1');
    div.setAttribute('title', _title);
    h.ImageElement img = new h.ImageElement();
    img.src = iconFilename;
    img.width = iconWidth;
    img.height = iconHeight;
    if (enabled)
      listener = div.onClick.listen((h.MouseEvent event) => action());
    div.append(img);
    return(div);
  }
  
  String get title {
    return(_title);
  }
  
  void set title(String t) {
    _title = t;
    h.Element div = getHTMLNode();
    div.setAttribute('title', _title);
  }
  
  h.Element getHTMLNode() {
    return(h.querySelector("#$id"));
  }
  
  void disable() {
    if (!enabled)
      return;
    enabled = false;
    h.Element div = getHTMLNode();
    div.classes.add('button-disabled');
    listener.cancel();
  }
  
  void enable() {
    if (enabled)
      return;
    enabled = true;
    h.Element div = getHTMLNode();
    div.classes.remove('button-disabled');
    listener = div.onClick.listen((h.MouseEvent event) => action());
  }
  
  void select() {
    if (selected)
      return;
    selected = true;
    h.Element div = getHTMLNode();
    div.classes.add('button-selected');
  }
  
  void deselect() {
    if (!selected)
      return;
    selected = false;
    h.Element div = getHTMLNode();
    div.classes.remove('button-selected');
  }
  
}
