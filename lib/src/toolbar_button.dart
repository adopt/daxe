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

typedef void ButtonAction(ToolbarButton button);

class ToolbarButton {
  static int idcount = 0;
  String _title;
  String iconFilename;
  ButtonAction action;
  Object data;
  String id;
  bool enabled;
  bool selected;
  StreamSubscription<h.MouseEvent> listener;
  
  ToolbarButton(this._title, this.iconFilename, this.action, {this.data, this.enabled:true}) {
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
    div.setAttribute('title', _title);
    h.ImageElement img = new h.ImageElement();
    img.setAttribute('src', 'packages/daxe/images/toolbar/' + iconFilename);
    if (enabled)
      listener = div.onClick.listen((h.MouseEvent event) => action(this));
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
    listener = div.onClick.listen((h.MouseEvent event) => action(this));
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
