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
  
  Menu(String title) : super(title, null) {
    items = new List<MenuItem>();
  }
  
  add(MenuItem item) {
    item.parent = this;
    items.add(item);
  }
  
  @override
  h.Element html() {
    h.DivElement div = new h.DivElement();
    div.classes.add('dropdown_menu');
    div.id = "menu_$id";
    h.TableElement table = new h.TableElement();
    table.classes.add('menu');
    for (MenuItem item in items) {
      table.append(item.html());
    }
    div.append(table);
    return(div);
  }
  
  void show() {
    h.DivElement div = getHTMLNode();
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
        (item as Menu).hide();
    }
    h.DivElement div = getHTMLNode();
    div.style.display = 'none';
  }
  
  bool isVisible() {
    h.DivElement div = getHTMLNode();
    return(div.style.display != 'none');
  }
  
  void addSeparator() {
    items.add(new MenuItem.separator());
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
