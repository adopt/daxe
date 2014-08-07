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

class Menu extends MenuItem {
  List<MenuItem> items;
  String menuid;
  
  Menu(String title) : super(title, null) {
    items = new List<MenuItem>();
    this.menuid = "menu_${MenuItem.itemidcount-1}";
  }
  
  add(MenuItem item) {
    item.parent = this;
    items.add(item);
  }
  
  @override
  h.Element htmlItem() {
    h.TableRowElement tr = new h.TableRowElement();
    tr.attributes['id'] = itemid;
    h.TableCellElement td = new h.TableCellElement();
    td.text = _title;
    td.onMouseOver.listen((h.MouseEvent event) {
      if (enabled) {
        select();
        show();
      }
    });
    tr.append(td);
    td = new h.TableCellElement();
    td.text = ">";
    h.DivElement divSubMenu = htmlMenu();
    divSubMenu.classes.remove('dropdown_menu');
    divSubMenu.classes.add('submenu');
    divSubMenu.style.display = 'none';
    td.append(divSubMenu);
    td.onMouseOver.listen((h.MouseEvent event) {
      if (enabled) {
        select();
        show();
      }
    });
    tr.append(td);
    if (!enabled)
      tr.classes.add('disabled');
    if (toolTipText != null)
      tr.title = toolTipText;
    return(tr);
  }
  
  h.Element htmlMenu() {
    h.DivElement div = new h.DivElement();
    div.classes.add('dropdown_menu');
    div.id = menuid;
    h.TableElement table = new h.TableElement();
    table.classes.add('menu');
    for (MenuItem item in items) {
      table.append(item.htmlItem());
    }
    div.append(table);
    return(div);
  }
  
  h.Element getMenuHTMLNode() {
    return(h.querySelector("#$menuid"));
  }
  
  void show() {
    h.DivElement div = getMenuHTMLNode();
    div.style.display = 'block';
    //h.SpanElement spanTitle = h.query("#menutitle_$id");
    // to avoid setting coordinates, we use a div with position absolute
    // and top 100% inside a div with position relative...
    //int top = spanTitle.offsetTop + spanTitle.offsetHeight;
    //int left = spanTitle.offsetLeft;
    //hMenu.style.top = "${top}px";
    //hMenu.style.left = "${left}px";
  }
  
  void hide() {
    for (MenuItem item in items) {
      if (item is Menu)
        item.hide();
      item.deselect();
    }
    h.DivElement div = getMenuHTMLNode();
    div.style.display = 'none';
  }
  
  bool isVisible() {
    h.DivElement div = getMenuHTMLNode();
    return(div.style.display != 'none');
  }
  
  void addSeparator() {
    items.add(new MenuItem.separator());
  }
  
  void deselectOtherItems(MenuItem menuitem) {
    for (MenuItem item in items) {
      if (item != menuitem)
        item.deselect();
    }
  }
  
  void set title(String title) {
    _title = title;
    h.Element hel = h.querySelector("#$itemid");
    if (hel is h.TableRowElement) {
      h.TableRowElement tr = hel;
      h.TableCellElement td = tr.nodes.first;
      td.text = title;
    } else if (hel is h.DivElement) {
      h.Node firstNode = hel.firstChild;
      if (firstNode is h.Text)
        firstNode.text = title;
    }
  }
  
  void checkEnabled() {
    bool en = false;
    for (MenuItem item in items) {
      if (item.enabled) {
        en = true;
        break;
      }
    }
    if (en == enabled)
      return;
    h.Element el = h.querySelector("#$itemid");
    if (en)
      el.classes.remove('disabled');
    else
      el.classes.add('disabled');
    enabled = en;
    if (parent != null)
      parent.checkEnabled();
  }
  
  /*
  @override
  void close() {
    if (parent != null)
      parent.close();
    else
      hide();
  }
  */
}
