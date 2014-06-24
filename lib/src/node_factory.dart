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

typedef DaxeNode ConstructorFromNode(x.Node node, DaxeNode parent);
typedef DaxeNode ConstructorFromRef(x.Element elementRef);

NodeFactory nodeFactory = new NodeFactory();

/**
 * Factory class to create DaxeNode objects based on an XML node or on a schema reference.
 */
class NodeFactory {
  
  // Note: it would have been nice to use mirrors to avoid defining constructors for each type,
  // but reflection can cause problems because of tree shaking in dart2js:
  // see caveat 4 in http://www.dartlang.org/articles/reflection-with-mirrors/
  // As a result, we are defining constructor functions for each type.
  // Additionnal types can be defined with NodeFactory.addDisplayType
  
  // TODO: add factory constructors in DaxeNode ?
  
  HashMap<String,ConstructorFromRef> constructorsFromRef = new HashMap<String,ConstructorFromRef>();
  
  HashMap<String,ConstructorFromNode> constructorsFromNode = new HashMap<String,ConstructorFromNode>();
  
  static void addCoreDisplayTypes() {
    // add core types in the nodes library
    NodeFactory.addDisplayType('division',
        (x.Element ref) => new DNDivision.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNDivision.fromNode(node, parent)
    );
    NodeFactory.addDisplayType('item',
        (x.Element ref) => new DNItem.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNItem.fromNode(node, parent)
    );
    NodeFactory.addDisplayType('liste',
        (x.Element ref) => new DNList.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNList.fromNode(node, parent)
    );
    NodeFactory.addDisplayType('fichier',
        (x.Element ref) => new DNFile.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNFile.fromNode(node, parent)
    );
    NodeFactory.addDisplayType('formulaire',
        (x.Element ref) => new DNForm.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNForm.fromNode(node, parent)
    );
    NodeFactory.addDisplayType('string',
        (x.Element ref) => new DNString.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNString.fromNode(node, parent)
    );
    NodeFactory.addDisplayType('style',
        (x.Element ref) => new DNStyle.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNStyle.fromNode(node, parent)
    );
    NodeFactory.addDisplayType('symbole2',
        (x.Element ref) => new DNSpecial.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNSpecial.fromNode(node, parent)
    );
    NodeFactory.addDisplayType('table',
        (x.Element ref) => new DNTable.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNTable.fromNode(node, parent)
    );
    NodeFactory.addDisplayType('tabletexte',
        (x.Element ref) => new DNTable.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNTable.fromNode(node, parent)
    );
    NodeFactory.addDisplayType('texte',
        null,
        (x.Node node, DaxeNode parent) => new DNText.fromNode(node, parent)
    );
    NodeFactory.addDisplayType('typesimple',
        (x.Element ref) => new DNSimpleType.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNSimpleType.fromNode(node, parent)
    );
    NodeFactory.addDisplayType('vide',
        (x.Element ref) => new DNEmpty.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNEmpty.fromNode(node, parent)
    );
    NodeFactory.addDisplayType('zone',
        (x.Element ref) => new DNArea.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNArea.fromNode(node, parent)
    );
  }
  
  static void addDisplayType(String displayType, ConstructorFromRef cref, ConstructorFromNode cnode) {
    if (cref != null)
      nodeFactory.constructorsFromRef[displayType] = cref;
    if (cnode != null)
      nodeFactory.constructorsFromNode[displayType] = cnode;
  }
  
  static DaxeNode createFromNode(x.Node n, DaxeNode parent) {
    x.Element ref;
    if (n is x.Document) {
      return(new DNDocument.fromNode(n));
    } else if (n is x.Comment) {
      return(new DNComment.fromNode(n, parent));
    } else if (n is x.ProcessingInstruction) {
      return(new DNProcessingInstruction.fromNode(n, parent));
    } else if (n is x.CDATASection) {
      return(new DNCData.fromNode(n, parent));
    }
    if (n is x.Element) {
      ref = doc.cfg.getElementRef(n, parent != null ? parent.ref : null);
    } else {
      ref = null;
    }
    String dt = doc.cfg.nodeDisplayType(ref, n.nodeName, n.nodeType);
    ConstructorFromNode cnode = nodeFactory.constructorsFromNode[dt];
    DaxeNode dn;
    if (cnode != null)
      dn = cnode(n, parent);
    else if (dt == 'plugin') {
      String className = doc.cfg.nodeParameterValue(ref, 'element', n.nodeName, "classe", null);
      if (className == 'xpages.JEEquationMemoire')
        dn = new DNEquationMem.fromNode(n, parent);
      else if (className == 'xpages.JEEquaTeXMemoire')
        dn = new DNEquaTexMem.fromNode(n, parent);
      else if (className == 'xpages.jeimage.JEImage')
        dn = new DNFile.fromNode(n, parent);
    } else
      dn = new DNString.fromNode(n, parent);
    return(dn);
  }
  
  static DaxeNode create(x.Element elementRef, [String nodeType = 'element']) {
    if (nodeType == 'commentaire') {
      return(new DNComment());
    } else if (nodeType == 'instruction') {
      return(new DNProcessingInstruction());
    } else if (nodeType == 'cdata') {
      return(new DNCData());
    }
    String dt = doc.cfg.nodeDisplayType(elementRef, doc.cfg.elementName(elementRef), x.Node.ELEMENT_NODE);
    ConstructorFromRef cref = nodeFactory.constructorsFromRef[dt];
    DaxeNode dn;
    if (cref != null)
      dn = cref(elementRef);
    else if (dt == 'plugin') {
      String className = doc.cfg.nodeParameterValue(elementRef, 'element', doc.cfg.elementName(elementRef), "classe", null);
      if (className == 'xpages.JEEquationMemoire')
        dn = new DNEquationMem.fromRef(elementRef);
      else if (className == 'xpages.JEEquaTeXMemoire')
        dn = new DNEquaTexMem.fromRef(elementRef);
      else if (className == 'xpages.jeimage.JEImage')
        dn = new DNFile.fromRef(elementRef);
    } else
      dn = new DNString.fromRef(elementRef);
    return(dn);
  }
}
