# Daxe
##Dart XML Editor

Daxe is an XML editor for the web. It works in the same way as [Jaxe](http://jaxe.sourceforge.net/en/), using a configuration file to define a GUI for each element of a given XML language. Like Jaxe, Daxe provides a graphical user interface, but it tries to be WYSIWYM rather than WYSIWYG.

Daxe is written in [Dart](https://www.dartlang.org/), which is transformed into Javascript to work in modern web browsers (it does not work on IE before version 9). It works without the need for a plugin, as opposed to the Jaxe applet which requires a Java plugin.

In itself, Daxe is not very useful, because it cannot open or save a local file (because of browser restrictions). It needs to be included into a larger system like a CMS. Daxe is now integrated into [WebJaxe](http://media4.obspm.fr/outils/webjaxe/en/), to provide an alternative to edition with the Jaxe applet. But it could be used in other systems, hence the separate release of the code.

##Licence

Daxe is licenced under the [GPL version 3](http://www.gnu.org/licenses/gpl-3.0.en.html) or later.

##Using Daxe

Daxe is using a whole HTML document, using the URL to read parameters. It can be included in an iframe to fit inside a larger document.
Parameters

* `config`: the relative path to the configuration file (required)
* `file`: the relative path to the file to be edited (optional, a new document is created if it is not specified)
* `save`: the relative path to the server script used to save a document (optional, the save menu does not appear if it is not specified)

Upon saving, the server script receives a POST request with the path of the document in the `path` parameter and its content in the `file` parameter. It replies with the text `ok` if no error occured, or a string starting with `error` if there was an error.

##Building and testing

* Install the [Dart SDK](https://www.dartlang.org/tools/sdk/).
* `./build.sh` (or just `pub build`) with pub on the PATH
* copy the `build/web` directory on a server (here localhost, with the contents of `build/web` inside a `daxe` directory)
* `http://localhost//daxe/daxe_js.html?config=config/XPAGES_config.xml`

##Documentation

Although it doesn't have as many features (especially anything requesting an access to local files), Daxe was designed to look like Jaxe, and use Jaxe configuration files. So Jaxe documentation can be used as well :

* [User guide](http://jaxe.sourceforge.net/en/pages_jaxe-user-guide/xml-pinciples.html)
* [Configuration file syntax](http://jaxe.sourceforge.net/en/pages_doc-config-en/intro-doc-config-en.html)

##Extending Daxe

As with Jaxe, it is possible to create new display types for elements. Since the programming language is not the same, it doesn't work in the same way.

Extensions have to be written in Dart. A new display type can be added by calling the `addDisplayType` function in the daxe library. Two constructors have to be provided to create a new `DaxeNode` (the equivalent of `JaxeElement` with Jaxe): one with a simple reference to the element in the schema (for new nodes), and one using a DOM node to create the node from an existing document.

Menu functions can also be added with `addCustomFunction`.
