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

part of nodes;

class BlockButton {
  static int idcount = 0;
  static final String iconPath = 'packages/daxe/images/';
  String _title;
  String iconFilename;
  ActionFunction action;
  String id;
  bool enabled;
  bool selected;
  StreamSubscription<h.MouseEvent> listener;
  
  BlockButton(this._title, this.iconFilename, this.action,
      {this.enabled:true, this.selected:false}) {
    id = "block_button_$idcount";
    idcount++;
  }
  
  h.Element html() {
    h.DivElement div = new h.DivElement();
    div.id = id;
    div.classes.add('dnblock-button');
    if (!enabled)
      div.classes.add('dnblock-button-disabled');
    if (selected)
      div.classes.add('dnblock-button-selected');
    div.setAttribute('title', _title);
    h.ImageElement img = new h.ImageElement();
    img.setAttribute('src', iconPath + iconFilename);
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
    div.classes.add('dnblock-button-disabled');
    listener.cancel();
  }
  
  void enable() {
    if (enabled)
      return;
    enabled = true;
    h.Element div = getHTMLNode();
    div.classes.remove('dnblock-button-disabled');
    listener = div.onClick.listen((h.MouseEvent event) => action());
  }
  
  void select() {
    if (selected)
      return;
    selected = true;
    h.Element div = getHTMLNode();
    div.classes.add('dnblock-button-selected');
  }
  
  void deselect() {
    if (!selected)
      return;
    selected = false;
    h.Element div = getHTMLNode();
    div.classes.remove('dnblock-button-selected');
  }
  
}
