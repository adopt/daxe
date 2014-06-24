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

class MenuItem {
  static int idcount = 0;
  String id;
  String _title;
  Menu parent;
  ActionFunction action;
  String shortcut;
  Object data;
  bool enabled;
  bool is_separator;
  String toolTipText;
  
  MenuItem(this._title, this.action, {this.shortcut, this.data}) {
    this.id = "menu_$idcount";
    idcount++;
    parent = null;
    enabled = true;
    is_separator = false;
  }
  
  MenuItem.separator() {
    is_separator = true;
  }
  
  h.Element html() {
    h.TableRowElement tr = new h.TableRowElement();
    if (is_separator) {
      h.TableCellElement td = new h.TableCellElement();
      td.appendText('-');
      tr.append(td);
    } else {
      tr.attributes['id'] = "menu_$id";
      h.TableCellElement td = new h.TableCellElement();
      td.text = _title;
      td.onMouseUp.listen((h.MouseEvent event) => activate());
      td.onMouseOver.listen((h.MouseEvent event) => select());
      td.onMouseOut.listen((h.MouseEvent event) => deselect());
      tr.append(td);
      td = new h.TableCellElement();
      if (this.shortcut != null)
        td.text = "Ctrl+$shortcut";
      tr.append(td);
      if (!enabled)
        tr.classes.add('disabled');
    }
    if (toolTipText != null)
      tr.title = toolTipText;
    return(tr);
  }
  
  h.Element getHTMLNode() {
    return(h.querySelector("#menu_$id"));
  }
  
  void activate() {
    if (!enabled)
      return;
    action();
  }
  
  void select() {
    if (!enabled)
      return;
    h.Element tr = getHTMLNode();
    tr.classes.add('selected');
  }
  
  void deselect() {
    if (!enabled)
      return;
    h.Element tr = getHTMLNode();
    if (tr != null)
      tr.classes.remove('selected');
  }
  
  void disable() {
    enabled = false;
    h.Element tr = getHTMLNode();
    tr.classes.remove('selected');
    tr.classes.add('disabled');
  }
  
  void enable() {
    enabled = true;
    h.Element tr = getHTMLNode();
    tr.classes.remove('disabled');
  }
  
  /*
  void close() {
    if (parent != null)
      parent.close();
  }
  */
  
  String get title {
    return(_title);
  }
  
  void set title(String title) {
    _title = title;
    h.TableRowElement tr = h.querySelector("#menu_$id");
    h.TableCellElement td = tr.nodes.first;
    td.text = title;
  }
}
