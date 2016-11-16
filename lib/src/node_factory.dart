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
  
  HashMap<String,ConstructorFromRef> _constructorsFromRef = new HashMap<String,ConstructorFromRef>();
  
  HashMap<String,ConstructorFromNode> _constructorsFromNode = new HashMap<String,ConstructorFromNode>();
  
  /**
   * Adds the core display types to the node library.
   */
  static void addCoreDisplayTypes() {
    setDisplayType('anchor',
        (x.Element ref) => new DNAnchor.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNAnchor.fromNode(node, parent)
    );
    setDisplayType('area',
        (x.Element ref) => new DNArea.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNArea.fromNode(node, parent)
    );
    setDisplayType('br',
        (x.Element ref) => new DNLineBreak.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNLineBreak.fromNode(node, parent)
    );
    setDisplayType('division',
        (x.Element ref) => new DNDivision.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNDivision.fromNode(node, parent)
    );
    setDisplayType('empty',
        (x.Element ref) => new DNEmpty.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNEmpty.fromNode(node, parent)
    );
    setDisplayType('equatexmem',
        (x.Element ref) => new DNEquaTexMem.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNEquaTexMem.fromNode(node, parent)
    );
    setDisplayType('equationmem',
        (x.Element ref) => new DNEquationMem.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNEquationMem.fromNode(node, parent)
    );
    setDisplayType('field',
        (x.Element ref) => new DNFormField.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNFormField.fromNode(node, parent)
    );
    setDisplayType('file',
        (x.Element ref) => new DNFile.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNFile.fromNode(node, parent)
    );
    setDisplayType('form',
        (x.Element ref) => new DNForm.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNForm.fromNode(node, parent)
    );
    setDisplayType('hiddendiv',
        (x.Element ref) => new DNHiddenDiv.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNHiddenDiv.fromNode(node, parent)
    );
    setDisplayType('hiddenp',
        (x.Element ref) => new DNHiddenP.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNHiddenP.fromNode(node, parent)
    );
    setDisplayType('hr',
          (x.Element ref) => new DNHr.fromRef(ref),
          (x.Node node, DaxeNode parent) => new DNHr.fromNode(node, parent)
      );
    setDisplayType('item',
        (x.Element ref) => new DNItem.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNItem.fromNode(node, parent)
    );
    setDisplayType('list',
        (x.Element ref) => new DNList.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNList.fromNode(node, parent)
    );
    setDisplayType('simpletype',
        (x.Element ref) => new DNSimpleType.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNSimpleType.fromNode(node, parent)
    );
    setDisplayType('string',
        (x.Element ref) => new DNString.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNString.fromNode(node, parent)
    );
    setDisplayType('style',
        (x.Element ref) => new DNStyle.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNStyle.fromNode(node, parent)
    );
    setDisplayType('stylespan',
        (x.Element ref) => new DNStyleSpan.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNStyleSpan.fromNode(node, parent)
    );
    setDisplayType('symbol',
        (x.Element ref) => new DNSpecial.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNSpecial.fromNode(node, parent)
    );
    setDisplayType('table',
        (x.Element ref) => new DNTable.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNTable.fromNode(node, parent)
    );
    setDisplayType('tr',
        (x.Element ref) => new DNTR.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNTR.fromNode(node, parent)
    );
    setDisplayType('td',
        (x.Element ref) => new DNTD.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNTD.fromNode(node, parent)
    );
    setDisplayType('th',
        (x.Element ref) => new DNTH.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNTH.fromNode(node, parent)
    );
    setDisplayType('text',
        null,
        (x.Node node, DaxeNode parent) => new DNText.fromNode(node, parent)
    );
    setDisplayType('witem',
        (x.Element ref) => new DNWItem.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNWItem.fromNode(node, parent)
    );
    setDisplayType('wlist',
        (x.Element ref) => new DNWList.fromRef(ref),
        (x.Node node, DaxeNode parent) => new DNWList.fromNode(node, parent)
    );
    setDisplayType('xmlcdata',
        (x.Element ref) => new DNCData(),
        (x.Node node, DaxeNode parent) => new DNCData.fromNode(node, parent)
    );
    setDisplayType('xmlcomment',
        (x.Element ref) => new DNComment(),
        (x.Node node, DaxeNode parent) => new DNComment.fromNode(node, parent)
    );
    setDisplayType('xmldocument',
        (x.Element ref) => new DNDocument(),
        (x.Node node, DaxeNode parent) => new DNDocument.fromNode(node)
    );
    setDisplayType('xmlpi',
        (x.Element ref) => new DNProcessingInstruction(),
        (x.Node node, DaxeNode parent) => new DNProcessingInstruction.fromNode(node, parent)
    );
  }
  
  /**
   * Adds a custom display type or changes a core one to create a
   * [DaxeNode] with an element reference or a DOM node.
   */
  static void setDisplayType(String displayType, ConstructorFromRef cref, ConstructorFromNode cnode) {
    if (cref != null)
      nodeFactory._constructorsFromRef[displayType] = cref;
    else
      nodeFactory._constructorsFromRef.remove(displayType);
    if (cnode != null)
      nodeFactory._constructorsFromNode[displayType] = cnode;
    else
      nodeFactory._constructorsFromNode.remove(displayType);
  }
  
  /**
   * Creates a new [DaxeNode] with the DOM node and the future parent
   * for the new node (the parent helps to choose an element
   * reference in the schema for the new node).
   */
  static DaxeNode createFromNode(x.Node n, DaxeNode parent) {
    x.Element ref;
    if (n is x.Element) {
      ref = doc.cfg.getElementRef(n, parent != null ? parent.ref : null);
    } else {
      ref = null;
    }
    String dt = doc.cfg.nodeDisplayType(ref, n.nodeName, n.nodeType);
    ConstructorFromNode cnode = nodeFactory._constructorsFromNode[dt];
    DaxeNode dn;
    if (cnode != null)
      dn = cnode(n, parent);
    else
      dn = new DNString.fromNode(n, parent);
    return(dn);
  }
  
  /**
   * Creates a new [DaxeNode] with a given element reference.
   * The [nodeType] parameter can be used for XML comments,
   * processing instructions and CDATA sections (they do not
   * have an element reference, so a null [elementRef] can be passed
   * for these nodes).
   */
  static DaxeNode create(x.Element elementRef, [String nodeType = 'element']) {
    int domNodeType;
    if (nodeType == 'element')
      domNodeType = x.Node.ELEMENT_NODE;
    else if (nodeType == 'document')
      domNodeType = x.Node.DOCUMENT_NODE;
    else if (nodeType == 'comment')
      domNodeType = x.Node.COMMENT_NODE;
    else if (nodeType == 'pi')
      domNodeType = x.Node.PROCESSING_INSTRUCTION_NODE;
    else if (nodeType == 'cdata')
      domNodeType = x.Node.CDATA_SECTION_NODE;
    else if (nodeType == 'text')
      domNodeType = x.Node.TEXT_NODE;
    String dt = doc.cfg.nodeDisplayType(elementRef, doc.cfg.elementName(elementRef), domNodeType);
    ConstructorFromRef cref = nodeFactory._constructorsFromRef[dt];
    DaxeNode dn;
    if (cref != null)
      dn = cref(elementRef);
    else
      dn = new DNString.fromRef(elementRef);
    return(dn);
  }
}
