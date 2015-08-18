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

/**
 * Image file. The image is displayed in the text if it is found,
 * otherwise an error message is displayed instead of the image.
 * Jaxe display type: 'fichier' (file).
 * 
 * Parameters:
 * - srcAtt: the name of the attribute giving the file path
 * - chooser: it set to true, use the file chooser to select the file
 *                         (see OpenDialog)
 * - widthAtt: the name of the attribute with the width (in pixels)
 * - heightAtt: the name of the attribute with the width (in pixels)
 */
class DNFile extends DaxeNode {
  h.ImageElement _img;
  String _srcAtt, _widthAtt, _heightAtt;
  bool chooser; // use the file chooser
  bool error; // error when loading the image
  
  DNFile.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
    initParams();
  }
  
  DNFile.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
    initParams();
  }
  
  void initParams() {
    _srcAtt = doc.cfg.elementParameterValue(ref, 'srcAtt', 'src');
    String chooserString = doc.cfg.elementParameterValue(ref, 'chooser', 'false');
    chooser = (chooserString == 'true' && doc.saveURL != null);
    _widthAtt = doc.cfg.elementParameterValue(ref, 'widthAtt', null);
    _heightAtt = doc.cfg.elementParameterValue(ref, 'heightAtt', null);
    error = (getAttribute(_srcAtt) == null);
  }
  
  @override
  h.Element html() {
    assert(doc.filePath != null);
    if (!error) {
      _img = new h.ImageElement();
      _img.id = "$id";
      _img.classes.add('dn');
      String folder = '';
      String xmlFilePath = doc.filePath;
      int ind = xmlFilePath.lastIndexOf('/');
      if (ind != -1)
        folder = xmlFilePath.substring(0, ind + 1);
      String src = "$folder${getAttribute(_srcAtt)}";
      _img.src = src;
      _img.alt = getAttribute(_srcAtt);
      _img.onLoad.listen((h.Event event) => _imageLoaded());
      _img.onClick.listen((h.MouseEvent event) => attributeDialog());
      _img.onError.listen((h.Event e) => _imageNotLoaded());
      return(_img);
    } else {
      h.SpanElement span = new h.SpanElement();
      span.id = "$id";
      span.classes.add('dn');
      span.classes.add('file-label');
      span.text = getAttribute(_srcAtt) != null ? getAttribute(_srcAtt) : '?';
      span.onClick.listen((h.MouseEvent event) => attributeDialog());
      return(span);
    }
  }
  
  void _imageLoaded() {
    if (_img.naturalWidth > 500) {
      _img.width = 500;
    }
    _fixCursorPosition();
  }
  
  void _imageNotLoaded() {
    error = true;
    updateHTML();
    _fixCursorPosition();
  }
  
  /**
   * fix cursor position if it is after the image/label
   * (called after the image is loaded)
   */
  void _fixCursorPosition() {
    if (page.getSelectionStart() != null &&
        page.getSelectionStart() > new Position(this, 0))
      page.cursor.updateCaretPosition(false);
  }
  
  @override
  Position firstCursorPositionInside() {
    return(null);
  }
  
  @override
  Position lastCursorPositionInside() {
    return(null);
  }
  
  @override
  void newNodeCreationUI(ActionFunction okfct) {
    if (!chooser) {
      super.newNodeCreationUI(okfct);
      return;
    }
    // display file chooser, set some attributes automatically, and
    // finish the element creation with the attribute dialog.
    Uri htmlUri = Uri.parse(h.window.location.toString());
    Uri docUri = Uri.parse(doc.filePath);
    List<String> segments = new List<String>.from(docUri.pathSegments);
    segments.removeLast();
    Uri openDir = docUri.replace(scheme:htmlUri.scheme, host:htmlUri.host,
        port:htmlUri.port, pathSegments:segments);
    FileChooser dlg;
    ActionFunction action = () {
      Uri imgUri = dlg.getSelectedUri();
      List<String> imgPathSegments = imgUri.pathSegments;
      // make path relative to the XML file:
      int baseInd = 0;
      for (int i=0; i<min(segments.length, imgPathSegments.length-1); i++) {
        if (segments[i] != imgPathSegments[i])
          break;
        baseInd++;
      }
      List<String> newSegments = new List<String>();
      for (int i=0; i<segments.length - baseInd; i++)
        newSegments.add('..');
      for (int i=baseInd; i<imgPathSegments.length; i++)
        newSegments.add(imgPathSegments[i]);
      // encode all segments before setting the attribute
      for (int i=0; i<newSegments.length; i++)
        newSegments[i] = Uri.encodeComponent(newSegments[i]);
      setAttribute(_srcAtt, newSegments.join('/'));
      if (_widthAtt != null && _heightAtt != null) {
        h.ImageElement img = new h.ImageElement();
        img.src = imgUri.path;
        img.onLoad.listen((h.Event event) {
          if (img.naturalWidth > 0 && img.naturalHeight > 0) {
            setAttribute(_widthAtt, img.naturalWidth.toString());
            setAttribute(_heightAtt, img.naturalHeight.toString());
          }
          super.newNodeCreationUI(okfct);
        });
      } else
        super.newNodeCreationUI(okfct);
    };
    dlg = new FileChooser(openDir, action);
    dlg.show();
  }
  
  @override
  void updateAttributes() {
    if (error)
      error = false;
    super.updateAttributes();
  }
}
