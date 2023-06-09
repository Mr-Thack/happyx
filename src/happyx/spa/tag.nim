## # Tag
## 
## Provides a Tag type that represents an HTML tag.
## The file includes several functions for initializing new HTML tags,
## adding child tags to existing tags, and
## getting the level of nesting for a tag within its parent tags.
## The file also includes a function for converting a tag and
## its child tags to a string representation with proper indentation and attributes.
import
  strutils,
  strformat,
  strtabs


type
  TagRef* = ref Tag
  Tag* = object
    name*: string
    parent*: TagRef
    attrs*: StringTableRef
    args*: seq[string]
    children*: seq[TagRef]
    isText*: bool  ## Ignore attributes and children when true
    onlyChildren*: bool  ## Ignore self and shows only children


const
  UnclosedTags* = ["input", "img", "meta", "br", "hr", "link"]


func initTag*(name: string, attrs: StringTableRef,
              children: seq[TagRef] = @[],
              onlyChildren: bool = false): TagRef =
  ## Initializes a new HTML tag with the given name, attributes, and children.
  ## 
  ## Args:
  ## - `name`: The name of the HTML tag to create.
  ## - `attrs`: The attributes to set for the HTML tag.
  ## - `children`: The children to add to the HTML tag.
  ## 
  ## Returns:
  ## - A reference to the newly created HTML tag.
  result = TagRef(
    name: name, isText: false, parent: nil,
    attrs: attrs, children: @[], args: @[],
    onlyChildren: onlyChildren
  )
  for child in children:
    if child.isNil():
      continue
    child.parent = result
    result.children.add(child)


func initTag*(name: string, children: seq[TagRef] = @[],
              onlyChildren: bool = false): TagRef =
  ## Initializes a new HTML tag without attributes but with children
  ## 
  ## Args:
  ## - `name`: tag name
  ## - `children`: The children to add to the HTML tag.
  ## 
  ## Returns:
  ## - A reference to the newly created HTML tag.
  result = TagRef(
    name: name, isText: false, parent: nil,
    attrs: newStringTable(), children: @[], args: @[],
    onlyChildren: onlyChildren
  )
  for child in children:
    if child.isNil():
      continue
    child.parent = result
    result.children.add(child)


func initTag*(name: string, isText: bool, attrs: StringTableRef,
              children: seq[TagRef] = @[],
              onlyChildren: bool = false): TagRef =
  ## Initializes a new HTML tag with the given name, whether it's text or not, attributes, and children.
  ## 
  ## Args:
  ## - `name`: The name of the HTML tag to create.
  ## - `isText`: Whether the tag represents text.
  ## - `attrs`: The attributes to set for the HTML tag.
  ## - `children`: The children to add to the HTML tag.
  ## 
  ## Returns:
  ## - A reference to the newly created HTML tag.
  result = TagRef(
    name: name, isText: isText, parent: nil,
    attrs: attrs, children: @[], args: @[],
    onlyChildren: onlyChildren
  )
  for child in children:
    if child.isNil():
      continue
    child.parent = result
    result.children.add(child)


func initTag*(name: string, isText: bool, children: seq[TagRef] = @[],
              onlyChildren: bool = false): TagRef =
  ## Initializes a new HTML tag
  result = TagRef(
    name: name, isText: isText, parent: nil,
    attrs: newStringTable(), children: @[], args: @[],
    onlyChildren: onlyChildren
  )
  for child in children:
    if child.isNil():
      continue
    child.parent = result
    result.children.add(child)


func tag*(name: string): TagRef {.inline.} =
  ## Shortcut for `initTag func<#initTag,string,seq[TagRef]>`_
  runnableExamples:
    var root = tag"div"
  TagRef(
    name: name, isText: false, parent: nil,
    attrs: newStringTable(), children: @[], args: @[],
    onlyChildren: false
  )


func tag*(tag: TagRef): TagRef {.inline.} =
  TagRef(
    name: tag.name, isText: tag.isText, parent: tag.parent,
    attrs: tag.attrs, children: tag.children,
    onlyChildren: tag.onlyChildren, args: @[],
  )


func textTag*(text: string): TagRef {.inline.} =
  ## Shortcur for `initTag func<#initTag,string,bool,seq[TagRef],bool>`_
  runnableExamples:
    var root = textTag"Hello, world!"
  TagRef(
    name: "", isText: true, parent: nil,
    attrs: newStringTable(), children: @[], args: @[],
    onlyChildren: false
  )


func add*(self: TagRef, tags: varargs[TagRef]) =
  ## Adds `other` tag into `self` tag
  runnableExamples:
    var
      rootTag = tag"div"
      child1 = tag"p"
      child2 = tag"p"
    rootTag.add(child1, child2)
  for tag in tags:
    if tag.isNil():
      continue
    self.children.add(tag)
    tag.parent = self


func addArg*(self: TagRef, arg: string) =
  self.args.add(arg)


func addArgIter*(self: TagRef, arg: string) =
  if self.args.len == 0:
    self.args.add(arg)
  # elif self.args.len == 1:
  #   self.args[0] = arg
  for i in self.children:
    i.addArgIter(arg)


func lvl*(self: TagRef): int =
  ## This function returns the level of nesting of the current tag within its parent tags.
  runnableExamples:
    var
      root = tag"div"
      child1 = tag"h1"
      child2 = tag"h2"
    root.add(child1)
    child1.add(child2)
    assert child2.lvl == 2
    assert child1.lvl == 1
    assert root.lvl == 0
  result = 0
  var tag = self
  while not isNil(tag.parent):
    tag = tag.parent
    if not tag.onlyChildren:
      inc result


func `[]`*(self: TagRef, attrName: string): string {.inline.} =
  ## Returns attribute by name
  self.attrs[attrName]


func `[]=`*(self: TagRef, attrName: string, attrValue: string) {.inline.} =
  ## Sets a new value for attribute or create new attribute
  self.attrs[attrName] = attrValue


func get*(self: TagRef, attrName: string, default: string): string {.inline.} =
  if attrName in self.attrs:
    self.attrs[attrName]
  else:
    default


func findByTag*(self: TagRef, tag: string): seq[TagRef] =
  ## Finds all tags by name
  result = @[]
  for child in self.children:
    if child.isText:
      continue
    for i in child.findByTag(tag):
      result.add(i)
    if child.name == tag:
      result.add(child)


func get*(self: TagRef, tag: string): TagRef =
  ## Returns tag by name
  for child in self.children:
    if tag == child.name:
      return child
  raise newException(ValueError, fmt"<{self.name}> at level [{self.lvl}] doesn't have tag <{tag}>")


func `$`*(self: TagRef): string =
  ## This function returns a string representation of the current tag and its child tags, if any.
  ## The function formats the tag with proper indentation based on the level of nesting
  ## and includes any attributes specified for the tag.
  ## If the tag is a text tag, the function simply returns the tag's name.
  let
    level = "  ".repeat(self.lvl)
    argsStr = self.args.join(" ")

  if self.isText:
    return level & self.name
  
  var attrs = ""
  for key, value in self.attrs.pairs():
    attrs &= " " & key & "=" & "\"" & value & "\""

  if self.onlyChildren:
    let children = self.children.join("\n")
    return fmt"{level}{children}{level}"

  if self.children.len > 0:
    let children = "\n" & self.children.join("\n") & "\n"
    fmt"{level}<{self.name}{attrs} {argsStr}>{children}{level}</{self.name}>"
  elif self.name in UnclosedTags:
    fmt"{level}<{self.name}{attrs} {argsStr}>"
  else:
    fmt"{level}<{self.name}{attrs} {argsStr}></{self.name}>"
