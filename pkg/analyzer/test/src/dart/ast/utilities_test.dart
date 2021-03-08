// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/elements_types_mixin.dart';
import '../../../generated/parser_test_base.dart' show ParserTestCase;
import '../../../util/ast_type_matchers.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NodeLocatorTest);
    defineReflectiveTests(NodeLocator2Test);
    defineReflectiveTests(ResolutionCopierTest);
  });
}

@reflectiveTest
class NodeLocator2Test extends ParserTestCase {
  void test_onlyStartOffset() {
    String code = ' int vv; ';
    //             012345678
    CompilationUnit unit = parseCompilationUnit(code);
    var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
    VariableDeclarationList variableList = declaration.variables;
    Identifier typeName = (variableList.type as TypeName).name;
    SimpleIdentifier varName = variableList.variables[0].name;
    expect(NodeLocator2(0).searchWithin(unit), same(unit));
    expect(NodeLocator2(1).searchWithin(unit), same(typeName));
    expect(NodeLocator2(2).searchWithin(unit), same(typeName));
    expect(NodeLocator2(3).searchWithin(unit), same(typeName));
    expect(NodeLocator2(4).searchWithin(unit), same(variableList));
    expect(NodeLocator2(5).searchWithin(unit), same(varName));
    expect(NodeLocator2(6).searchWithin(unit), same(varName));
    expect(NodeLocator2(7).searchWithin(unit), same(declaration));
    expect(NodeLocator2(8).searchWithin(unit), same(unit));
    expect(NodeLocator2(9).searchWithin(unit), isNull);
    expect(NodeLocator2(100).searchWithin(unit), isNull);
  }

  void test_startEndOffset() {
    String code = ' int vv; ';
    //             012345678
    CompilationUnit unit = parseCompilationUnit(code);
    var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
    VariableDeclarationList variableList = declaration.variables;
    Identifier typeName = (variableList.type as TypeName).name;
    SimpleIdentifier varName = variableList.variables[0].name;
    expect(NodeLocator2(-1, 2).searchWithin(unit), isNull);
    expect(NodeLocator2(0, 2).searchWithin(unit), same(unit));
    expect(NodeLocator2(1, 2).searchWithin(unit), same(typeName));
    expect(NodeLocator2(1, 3).searchWithin(unit), same(typeName));
    expect(NodeLocator2(1, 4).searchWithin(unit), same(variableList));
    expect(NodeLocator2(5, 6).searchWithin(unit), same(varName));
    expect(NodeLocator2(5, 7).searchWithin(unit), same(declaration));
    expect(NodeLocator2(5, 8).searchWithin(unit), same(unit));
    expect(NodeLocator2(5, 100).searchWithin(unit), isNull);
    expect(NodeLocator2(100, 200).searchWithin(unit), isNull);
  }
}

@reflectiveTest
class NodeLocatorTest extends ParserTestCase {
  void test_range() {
    CompilationUnit unit = parseCompilationUnit("library myLib;");
    var node = _assertLocate(unit, 4, 10);
    expect(node, isLibraryDirective);
  }

  void test_searchWithin_null() {
    NodeLocator locator = NodeLocator(0, 0);
    expect(locator.searchWithin(null), isNull);
  }

  void test_searchWithin_offset() {
    CompilationUnit unit = parseCompilationUnit("library myLib;");
    var node = _assertLocate(unit, 10, 10);
    expect(node, isSimpleIdentifier);
  }

  void test_searchWithin_offsetAfterNode() {
    CompilationUnit unit = parseCompilationUnit(r'''
class A {}
class B {}''');
    NodeLocator locator = NodeLocator(1024, 1024);
    var node = locator.searchWithin(unit.declarations[0]);
    expect(node, isNull);
  }

  void test_searchWithin_offsetBeforeNode() {
    CompilationUnit unit = parseCompilationUnit(r'''
class A {}
class B {}''');
    NodeLocator locator = NodeLocator(0, 0);
    var node = locator.searchWithin(unit.declarations[1]);
    expect(node, isNull);
  }

  AstNode _assertLocate(
    CompilationUnit unit,
    int start,
    int end,
  ) {
    NodeLocator locator = NodeLocator(start, end);
    var node = locator.searchWithin(unit)!;
    expect(locator.foundNode, same(node));
    expect(node.offset <= start, isTrue, reason: "Node starts after range");
    expect(node.offset + node.length > end, isTrue,
        reason: "Node ends before range");
    return node;
  }
}

@reflectiveTest
class ResolutionCopierTest with ElementsTypesMixin {
  @override
  final TypeProvider typeProvider = TestTypeProvider();

  void test_topLevelVariableDeclaration_external() {
    var fromNode = AstTestFactory.topLevelVariableDeclaration2(
        Keyword.VAR, [AstTestFactory.variableDeclaration('x')],
        isExternal: false);
    TopLevelVariableElement element = TopLevelVariableElementImpl('x', -1);
    fromNode.variables.variables[0].name.staticElement = element;
    TopLevelVariableDeclaration toNode1 =
        AstTestFactory.topLevelVariableDeclaration2(
            Keyword.VAR, [AstTestFactory.variableDeclaration('x')],
            isExternal: false);
    ResolutionCopier.copyResolutionData(fromNode, toNode1);
    // Nodes matched so resolution data should have been copied.
    expect(toNode1.variables.variables[0].declaredElement, same(element));
    TopLevelVariableDeclaration toNode2 =
        AstTestFactory.topLevelVariableDeclaration2(
            Keyword.VAR, [AstTestFactory.variableDeclaration('x')],
            isExternal: true);
    ResolutionCopier.copyResolutionData(fromNode, toNode1);
    // Nodes didn't match so resolution data should not have been copied.
    expect(toNode2.variables.variables[0].declaredElement, isNull);
  }

  void test_visitAdjacentStrings() {
    AdjacentStringsImpl createNode() => astFactory.adjacentStrings([
          astFactory.simpleStringLiteral(
            TokenFactory.tokenFromString('hello'),
            'hello',
          ),
          astFactory.simpleStringLiteral(
            TokenFactory.tokenFromString('world'),
            'world',
          )
        ]);

    var fromNode = createNode();
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('B'));
    fromNode.staticType = staticType;

    AdjacentStrings toNode = createNode();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticType, same(staticType));
  }

  void test_visitAnnotation() {
    String annotationName = "proxy";
    var fromNode =
        AstTestFactory.annotation(AstTestFactory.identifier3(annotationName));
    Element element = ElementFactory.topLevelVariableElement2(annotationName);
    fromNode.element = element;
    Annotation toNode =
        AstTestFactory.annotation(AstTestFactory.identifier3(annotationName));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.element, same(element));
  }

  void test_visitAnnotation_generic() {
    var annotationClassName = "A";
    var annotationConstructorName = "named";
    var argumentName = "x";
    var fromNode = AstTestFactory.annotation2(
        AstTestFactory.identifier3(annotationClassName),
        AstTestFactory.identifier3(annotationConstructorName),
        AstTestFactory.argumentList(
            [AstTestFactory.identifier3(argumentName)]));
    var elementA = ElementFactory.classElement2(annotationClassName, ['T']);
    var element = ElementFactory.constructorElement(
        elementA, annotationConstructorName, true, [typeProvider.dynamicType]);
    fromNode.element = element;
    var typeArgumentName = 'U';
    var elementU = ElementFactory.classElement2(typeArgumentName);
    fromNode.typeArguments =
        AstTestFactory.typeArgumentList2([AstTestFactory.typeName(elementU)]);
    var toNode = AstTestFactory.annotation2(
        AstTestFactory.identifier3(annotationClassName),
        AstTestFactory.identifier3(annotationConstructorName),
        AstTestFactory.argumentList(
            [AstTestFactory.identifier3(argumentName)]));
    toNode.typeArguments = AstTestFactory.typeArgumentList2(
        [AstTestFactory.typeName4(typeArgumentName)]);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.element, same(element));
    expect(
        (toNode.typeArguments!.arguments.single as TypeName).name.staticElement,
        same(elementU));
  }

  void test_visitAsExpression() {
    var fromNode = AstTestFactory.asExpression(
        AstTestFactory.identifier3("x"), AstTestFactory.typeName4("A"));
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('B'));
    fromNode.staticType = staticType;
    AsExpression toNode = AstTestFactory.asExpression(
        AstTestFactory.identifier3("x"), AstTestFactory.typeName4("A"));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticType, same(staticType));
  }

  void test_visitAssignmentExpression() {
    var fromNode = AstTestFactory.assignmentExpression(
        AstTestFactory.identifier3("a"),
        TokenType.PLUS_EQ,
        AstTestFactory.identifier3("b"));
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    MethodElement staticElement = ElementFactory.methodElement("+", staticType);
    fromNode.staticElement = staticElement;
    fromNode.staticType = staticType;
    AssignmentExpression toNode = AstTestFactory.assignmentExpression(
        AstTestFactory.identifier3("a"),
        TokenType.PLUS_EQ,
        AstTestFactory.identifier3("b"));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticElement, same(staticElement));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitBinaryExpression() {
    var fromNode = AstTestFactory.binaryExpression(
        AstTestFactory.identifier3("a"),
        TokenType.PLUS,
        AstTestFactory.identifier3("b"));
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    MethodElement staticElement = ElementFactory.methodElement("+", staticType);
    fromNode.staticElement = staticElement;
    fromNode.staticType = staticType;
    BinaryExpression toNode = AstTestFactory.binaryExpression(
        AstTestFactory.identifier3("a"),
        TokenType.PLUS,
        AstTestFactory.identifier3("b"));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticElement, same(staticElement));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitBooleanLiteral() {
    var fromNode = AstTestFactory.booleanLiteral(true);
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;
    BooleanLiteral toNode = AstTestFactory.booleanLiteral(true);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticType, same(staticType));
  }

  void test_visitCascadeExpression() {
    var fromNode = AstTestFactory.cascadeExpression(
        AstTestFactory.identifier3("a"), [AstTestFactory.identifier3("b")]);
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;
    CascadeExpression toNode = AstTestFactory.cascadeExpression(
        AstTestFactory.identifier3("a"), [AstTestFactory.identifier3("b")]);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticType, same(staticType));
  }

  void test_visitCompilationUnit() {
    var fromNode = AstTestFactory.compilationUnit();
    CompilationUnitElement element = CompilationUnitElementImpl();
    fromNode.element = element;
    CompilationUnit toNode = AstTestFactory.compilationUnit();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.declaredElement, same(element));
  }

  void test_visitConditionalExpression() {
    var fromNode = AstTestFactory.conditionalExpression(
        AstTestFactory.identifier3("c"),
        AstTestFactory.identifier3("a"),
        AstTestFactory.identifier3("b"));
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;
    ConditionalExpression toNode = AstTestFactory.conditionalExpression(
        AstTestFactory.identifier3("c"),
        AstTestFactory.identifier3("a"),
        AstTestFactory.identifier3("b"));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticType, same(staticType));
  }

  void test_visitConstructorDeclaration() {
    String className = "A";
    String constructorName = "c";
    var fromNode = AstTestFactory.constructorDeclaration(
        AstTestFactory.identifier3(className),
        constructorName,
        AstTestFactory.formalParameterList(), []);
    ConstructorElement element = ElementFactory.constructorElement2(
        ElementFactory.classElement2(className), constructorName);
    fromNode.declaredElement = element;
    ConstructorDeclaration toNode = AstTestFactory.constructorDeclaration(
        AstTestFactory.identifier3(className),
        constructorName,
        AstTestFactory.formalParameterList(), []);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.declaredElement, same(element));
  }

  void test_visitConstructorName() {
    var fromNode =
        AstTestFactory.constructorName(AstTestFactory.typeName4("A"), "c");
    ConstructorElement staticElement = ElementFactory.constructorElement2(
        ElementFactory.classElement2("A"), "c");
    fromNode.staticElement = staticElement;
    ConstructorName toNode =
        AstTestFactory.constructorName(AstTestFactory.typeName4("A"), "c");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticElement, same(staticElement));
  }

  void test_visitDoubleLiteral() {
    var fromNode = AstTestFactory.doubleLiteral(1.0);
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;
    DoubleLiteral toNode = AstTestFactory.doubleLiteral(1.0);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticType, same(staticType));
  }

  void test_visitExportDirective() {
    var fromNode = AstTestFactory.exportDirective2("dart:uri");
    ExportElement element = ExportElementImpl(-1);
    fromNode.element = element;
    ExportDirective toNode = AstTestFactory.exportDirective2("dart:uri");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.element, same(element));
  }

  void test_visitFieldDeclaration_abstract() {
    FieldDeclaration fromNode = AstTestFactory.fieldDeclaration(
        false, Keyword.VAR, null, [AstTestFactory.variableDeclaration('x')],
        isAbstract: false);
    FieldElement element = FieldElementImpl('x', -1);
    (fromNode.fields.variables[0] as VariableDeclarationImpl)
        .name
        .staticElement = element;
    FieldDeclaration toNode1 = AstTestFactory.fieldDeclaration(
        false, Keyword.VAR, null, [AstTestFactory.variableDeclaration('x')],
        isAbstract: false);
    ResolutionCopier.copyResolutionData(fromNode, toNode1);
    // Nodes matched so resolution data should have been copied.
    expect(toNode1.fields.variables[0].declaredElement, same(element));
    FieldDeclaration toNode2 = AstTestFactory.fieldDeclaration(
        false, Keyword.VAR, null, [AstTestFactory.variableDeclaration('x')],
        isAbstract: true);
    ResolutionCopier.copyResolutionData(fromNode, toNode1);
    // Nodes didn't match so resolution data should not have been copied.
    expect(toNode2.fields.variables[0].declaredElement, isNull);
  }

  void test_visitFieldDeclaration_external() {
    FieldDeclaration fromNode = AstTestFactory.fieldDeclaration(
        false, Keyword.VAR, null, [AstTestFactory.variableDeclaration('x')],
        isExternal: false);
    FieldElement element = FieldElementImpl('x', -1);
    (fromNode.fields.variables[0] as VariableDeclarationImpl)
        .name
        .staticElement = element;
    FieldDeclaration toNode1 = AstTestFactory.fieldDeclaration(
        false, Keyword.VAR, null, [AstTestFactory.variableDeclaration('x')],
        isExternal: false);
    ResolutionCopier.copyResolutionData(fromNode, toNode1);
    // Nodes matched so resolution data should have been copied.
    expect(toNode1.fields.variables[0].declaredElement, same(element));
    FieldDeclaration toNode2 = AstTestFactory.fieldDeclaration(
        false, Keyword.VAR, null, [AstTestFactory.variableDeclaration('x')],
        isExternal: true);
    ResolutionCopier.copyResolutionData(fromNode, toNode1);
    // Nodes didn't match so resolution data should not have been copied.
    expect(toNode2.fields.variables[0].declaredElement, isNull);
  }

  void test_visitForEachPartsWithDeclaration() {
    ForEachPartsWithDeclaration createNode() =>
        astFactory.forEachPartsWithDeclaration(
            loopVariable: AstTestFactory.declaredIdentifier3('a'),
            inKeyword: TokenFactory.tokenFromKeyword(Keyword.IN),
            iterable: AstTestFactory.identifier3('b'));

    DartType typeB = interfaceTypeStar(ElementFactory.classElement2('B'));

    ForEachPartsWithDeclaration fromNode = createNode();
    (fromNode.iterable as SimpleIdentifierImpl).staticType = typeB;

    ForEachPartsWithDeclaration toNode = createNode();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect((toNode.iterable as SimpleIdentifier).staticType, same(typeB));
  }

  void test_visitForEachPartsWithIdentifier() {
    ForEachPartsWithIdentifierImpl createNode() =>
        astFactory.forEachPartsWithIdentifier(
            identifier: AstTestFactory.identifier3('a'),
            inKeyword: TokenFactory.tokenFromKeyword(Keyword.IN),
            iterable: AstTestFactory.identifier3('b'));

    DartType typeA = interfaceTypeStar(ElementFactory.classElement2('A'));
    DartType typeB = interfaceTypeStar(ElementFactory.classElement2('B'));

    var fromNode = createNode();
    fromNode.identifier.staticType = typeA;
    (fromNode.iterable as SimpleIdentifierImpl).staticType = typeB;

    ForEachPartsWithIdentifier toNode = createNode();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.identifier.staticType, same(typeA));
    expect((toNode.iterable as SimpleIdentifier).staticType, same(typeB));
  }

  void test_visitForElement() {
    ForElementImpl createNode() => astFactory.forElement(
        forKeyword: TokenFactory.tokenFromKeyword(Keyword.FOR),
        leftParenthesis: TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
        forLoopParts: astFactory.forEachPartsWithIdentifier(
            identifier: AstTestFactory.identifier3('a'),
            inKeyword: TokenFactory.tokenFromKeyword(Keyword.IN),
            iterable: AstTestFactory.identifier3('b')),
        rightParenthesis: TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
        body: AstTestFactory.identifier3('c'));

    DartType typeC = interfaceTypeStar(ElementFactory.classElement2('C'));

    ForElement fromNode = createNode();
    (fromNode.body as SimpleIdentifierImpl).staticType = typeC;

    ForElement toNode = createNode();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect((toNode.body as SimpleIdentifier).staticType, same(typeC));
  }

  void test_visitForPartsWithDeclarations() {
    ForPartsWithDeclarations createNode() =>
        astFactory.forPartsWithDeclarations(
            variables: AstTestFactory.variableDeclarationList2(
                Keyword.VAR, [AstTestFactory.variableDeclaration('a')]),
            leftSeparator: TokenFactory.tokenFromType(TokenType.SEMICOLON),
            condition: AstTestFactory.identifier3('b'),
            rightSeparator: TokenFactory.tokenFromType(TokenType.SEMICOLON),
            updaters: [AstTestFactory.identifier3('c')]);

    DartType typeB = interfaceTypeStar(ElementFactory.classElement2('B'));
    DartType typeC = interfaceTypeStar(ElementFactory.classElement2('C'));

    ForPartsWithDeclarations fromNode = createNode();
    (fromNode.condition as SimpleIdentifierImpl).staticType = typeB;
    (fromNode.updaters[0] as SimpleIdentifierImpl).staticType = typeC;

    ForPartsWithDeclarations toNode = createNode();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect((toNode.condition as SimpleIdentifier).staticType, same(typeB));
    expect((toNode.updaters[0] as SimpleIdentifier).staticType, same(typeC));
  }

  void test_visitForPartsWithExpression() {
    ForPartsWithExpression createNode() => astFactory.forPartsWithExpression(
        initialization: AstTestFactory.identifier3('a'),
        leftSeparator: TokenFactory.tokenFromType(TokenType.SEMICOLON),
        condition: AstTestFactory.identifier3('b'),
        rightSeparator: TokenFactory.tokenFromType(TokenType.SEMICOLON),
        updaters: [AstTestFactory.identifier3('c')]);

    DartType typeA = interfaceTypeStar(ElementFactory.classElement2('A'));
    DartType typeB = interfaceTypeStar(ElementFactory.classElement2('B'));
    DartType typeC = interfaceTypeStar(ElementFactory.classElement2('C'));

    ForPartsWithExpression fromNode = createNode();
    (fromNode.initialization as SimpleIdentifierImpl).staticType = typeA;
    (fromNode.condition as SimpleIdentifierImpl).staticType = typeB;
    (fromNode.updaters[0] as SimpleIdentifierImpl).staticType = typeC;

    ForPartsWithExpression toNode = createNode();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect((toNode.initialization as SimpleIdentifier).staticType, same(typeA));
    expect((toNode.condition as SimpleIdentifier).staticType, same(typeB));
    expect((toNode.updaters[0] as SimpleIdentifier).staticType, same(typeC));
  }

  void test_visitForStatement() {
    ForStatement createNode() => astFactory.forStatement(
        forKeyword: TokenFactory.tokenFromKeyword(Keyword.FOR),
        leftParenthesis: TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
        forLoopParts: astFactory.forEachPartsWithIdentifier(
            identifier: AstTestFactory.identifier3('a'),
            inKeyword: TokenFactory.tokenFromKeyword(Keyword.IN),
            iterable: AstTestFactory.identifier3('b')),
        rightParenthesis: TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
        body: AstTestFactory.expressionStatement(
            AstTestFactory.identifier3('c')));

    DartType typeA = interfaceTypeStar(ElementFactory.classElement2('A'));
    DartType typeB = interfaceTypeStar(ElementFactory.classElement2('B'));
    DartType typeC = interfaceTypeStar(ElementFactory.classElement2('C'));

    ForStatement fromNode = createNode();
    var fromForLoopParts =
        fromNode.forLoopParts as ForEachPartsWithIdentifierImpl;
    fromForLoopParts.identifier.staticType = typeA;
    fromForLoopParts.iterable.staticType = typeB;
    (fromNode.body as ExpressionStatementImpl).expression.staticType = typeC;

    ForStatement toNode = createNode();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    var toForLoopParts = fromNode.forLoopParts as ForEachPartsWithIdentifier;
    expect(toForLoopParts.identifier.staticType, same(typeA));
    expect(
        (toForLoopParts.iterable as SimpleIdentifier).staticType, same(typeB));
    expect(
        ((toNode.body as ExpressionStatement).expression as SimpleIdentifier)
            .staticType,
        same(typeC));
  }

  void test_visitFunctionExpression() {
    var fromNode = AstTestFactory.functionExpression2(
        AstTestFactory.formalParameterList(),
        AstTestFactory.emptyFunctionBody());
    MethodElement element = ElementFactory.methodElement(
        "m", interfaceTypeStar(ElementFactory.classElement2('C')));
    fromNode.declaredElement = element;
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;
    FunctionExpression toNode = AstTestFactory.functionExpression2(
        AstTestFactory.formalParameterList(),
        AstTestFactory.emptyFunctionBody());
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.declaredElement, same(element));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitFunctionExpressionInvocation() {
    var fromNode = AstTestFactory.functionExpressionInvocation(
        AstTestFactory.identifier3("f"));
    MethodElement staticElement = ElementFactory.methodElement(
        "m", interfaceTypeStar(ElementFactory.classElement2('C')));
    fromNode.staticElement = staticElement;
    var toNode = AstTestFactory.functionExpressionInvocation(
        AstTestFactory.identifier3("f"));
    ClassElement elementT = ElementFactory.classElement2('T');
    fromNode.typeArguments = AstTestFactory.typeArgumentList(
        <TypeAnnotation>[AstTestFactory.typeName(elementT)]);
    toNode.typeArguments = AstTestFactory.typeArgumentList(
        <TypeAnnotation>[AstTestFactory.typeName4('T')]);

    _copyAndVerifyInvocation(fromNode, toNode);

    expect(toNode.staticElement, same(staticElement));
  }

  void test_visitIfElement() {
    IfElementImpl createNode() => astFactory.ifElement(
        ifKeyword: TokenFactory.tokenFromKeyword(Keyword.IF),
        leftParenthesis: TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
        condition: AstTestFactory.identifier3('a'),
        rightParenthesis: TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
        thenElement: AstTestFactory.identifier3('b'),
        elseElement: AstTestFactory.identifier3('c'));

    DartType typeA = interfaceTypeStar(ElementFactory.classElement2('A'));
    DartType typeB = interfaceTypeStar(ElementFactory.classElement2('B'));
    DartType typeC = interfaceTypeStar(ElementFactory.classElement2('C'));

    var fromNode = createNode();
    (fromNode.condition as SimpleIdentifierImpl).staticType = typeA;
    (fromNode.thenElement as SimpleIdentifierImpl).staticType = typeB;
    (fromNode.elseElement as SimpleIdentifierImpl).staticType = typeC;

    IfElement toNode = createNode();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.condition.staticType, same(typeA));
    expect((toNode.thenElement as SimpleIdentifier).staticType, same(typeB));
    expect((toNode.elseElement as SimpleIdentifier).staticType, same(typeC));
  }

  void test_visitImportDirective() {
    var fromNode = AstTestFactory.importDirective3("dart:uri", null);
    ImportElement element = ImportElementImpl(0);
    fromNode.element = element;
    ImportDirective toNode = AstTestFactory.importDirective3("dart:uri", null);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.element, same(element));
  }

  void test_visitIndexExpression() {
    var fromNode = AstTestFactory.indexExpression(
      target: AstTestFactory.identifier3("a"),
      index: AstTestFactory.integer(0),
    );
    MethodElement staticElement = ElementFactory.methodElement(
        "m", interfaceTypeStar(ElementFactory.classElement2('C')));
    fromNode.staticElement = staticElement;
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;
    IndexExpression toNode = AstTestFactory.indexExpression(
      target: AstTestFactory.identifier3("a"),
      index: AstTestFactory.integer(0),
    );
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticElement, same(staticElement));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitInstanceCreationExpression() {
    var fromNode = AstTestFactory.instanceCreationExpression2(
        Keyword.NEW, AstTestFactory.typeName4("C"));
    ConstructorElement staticElement = ElementFactory.constructorElement2(
        ElementFactory.classElement2("C"), null);
    fromNode.constructorName.staticElement = staticElement;
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;
    InstanceCreationExpression toNode =
        AstTestFactory.instanceCreationExpression2(
            Keyword.NEW, AstTestFactory.typeName4("C"));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.constructorName.staticElement, same(staticElement));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitIntegerLiteral() {
    var fromNode = AstTestFactory.integer(2);
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;
    IntegerLiteral toNode = AstTestFactory.integer(2);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticType, same(staticType));
  }

  void test_visitIsExpression() {
    var fromNode = AstTestFactory.isExpression(
        AstTestFactory.identifier3("x"), false, AstTestFactory.typeName4("A"));
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;
    IsExpression toNode = AstTestFactory.isExpression(
        AstTestFactory.identifier3("x"), false, AstTestFactory.typeName4("A"));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticType, same(staticType));
  }

  void test_visitLibraryIdentifier() {
    var fromNode =
        AstTestFactory.libraryIdentifier([AstTestFactory.identifier3("lib")]);
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;
    LibraryIdentifier toNode =
        AstTestFactory.libraryIdentifier([AstTestFactory.identifier3("lib")]);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticType, same(staticType));
  }

  void test_visitListLiteral() {
    ListLiteralImpl createNode() => astFactory.listLiteral(
          null,
          AstTestFactory.typeArgumentList([AstTestFactory.typeName4('A')]),
          TokenFactory.tokenFromType(TokenType.OPEN_SQUARE_BRACKET),
          [AstTestFactory.identifier3('b')],
          TokenFactory.tokenFromType(TokenType.CLOSE_SQUARE_BRACKET),
        );

    DartType typeA = interfaceTypeStar(ElementFactory.classElement2('A'));
    DartType typeB = interfaceTypeStar(ElementFactory.classElement2('B'));
    DartType typeC = interfaceTypeStar(ElementFactory.classElement2('C'));

    var fromNode = createNode();
    (fromNode.typeArguments!.arguments[0] as TypeNameImpl).type = typeA;
    (fromNode.elements[0] as SimpleIdentifierImpl).staticType = typeB;
    fromNode.staticType = typeC;

    ListLiteral toNode = createNode();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect((toNode.typeArguments!.arguments[0] as TypeName).type, same(typeA));
    expect((toNode.elements[0] as SimpleIdentifier).staticType, same(typeB));
    expect(fromNode.staticType, same(typeC));
  }

  void test_visitMapLiteral() {
    var fromNode = AstTestFactory.setOrMapLiteral(null, null);
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;
    SetOrMapLiteral toNode = AstTestFactory.setOrMapLiteral(null, null);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticType, same(staticType));
  }

  void test_visitMethodInvocation() {
    var fromNode = AstTestFactory.methodInvocation2("m");
    var toNode = AstTestFactory.methodInvocation2("m");
    ClassElement elementT = ElementFactory.classElement2('T');
    fromNode.typeArguments = AstTestFactory.typeArgumentList(
        <TypeAnnotation>[AstTestFactory.typeName(elementT)]);
    toNode.typeArguments = AstTestFactory.typeArgumentList(
        <TypeAnnotation>[AstTestFactory.typeName4('T')]);
    _copyAndVerifyInvocation(fromNode, toNode);
  }

  void test_visitNamedExpression() {
    var fromNode =
        AstTestFactory.namedExpression2("n", AstTestFactory.integer(0));
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;
    NamedExpression toNode =
        AstTestFactory.namedExpression2("n", AstTestFactory.integer(0));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticType, same(staticType));
  }

  void test_visitNullLiteral() {
    var fromNode = AstTestFactory.nullLiteral();
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;
    NullLiteral toNode = AstTestFactory.nullLiteral();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticType, same(staticType));
  }

  void test_visitParenthesizedExpression() {
    var fromNode =
        AstTestFactory.parenthesizedExpression(AstTestFactory.integer(0));
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;
    ParenthesizedExpression toNode =
        AstTestFactory.parenthesizedExpression(AstTestFactory.integer(0));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticType, same(staticType));
  }

  void test_visitPartDirective() {
    var fromNode = AstTestFactory.partDirective2("part.dart");
    LibraryElement element = LibraryElementImpl(
        _AnalysisContextMock(),
        _AnalysisSessionMock(),
        'lib',
        -1,
        0,
        FeatureSet.latestLanguageVersion());
    fromNode.element = element;
    PartDirective toNode = AstTestFactory.partDirective2("part.dart");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.element, same(element));
  }

  void test_visitPartOfDirective() {
    var fromNode = AstTestFactory.partOfDirective(
        AstTestFactory.libraryIdentifier2(["lib"]));
    LibraryElement element = LibraryElementImpl(
        _AnalysisContextMock(),
        _AnalysisSessionMock(),
        'lib',
        -1,
        0,
        FeatureSet.latestLanguageVersion());
    fromNode.element = element;
    PartOfDirective toNode = AstTestFactory.partOfDirective(
        AstTestFactory.libraryIdentifier2(["lib"]));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.element, same(element));
  }

  void test_visitPostfixExpression() {
    String variableName = "x";
    var fromNode = AstTestFactory.postfixExpression(
        AstTestFactory.identifier3(variableName), TokenType.PLUS_PLUS);
    MethodElement staticElement = ElementFactory.methodElement(
        "+", interfaceTypeStar(ElementFactory.classElement2('C')));
    fromNode.staticElement = staticElement;
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;
    PostfixExpression toNode = AstTestFactory.postfixExpression(
        AstTestFactory.identifier3(variableName), TokenType.PLUS_PLUS);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticElement, same(staticElement));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitPrefixedIdentifier() {
    var fromNode = AstTestFactory.identifier5("p", "f");
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;
    PrefixedIdentifier toNode = AstTestFactory.identifier5("p", "f");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticType, same(staticType));
  }

  void test_visitPrefixExpression() {
    var fromNode = AstTestFactory.prefixExpression(
        TokenType.PLUS_PLUS, AstTestFactory.identifier3("x"));
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    MethodElement staticElement = ElementFactory.methodElement(
        "+", interfaceTypeStar(ElementFactory.classElement2('C')));
    fromNode.staticElement = staticElement;
    fromNode.staticType = staticType;
    PrefixExpression toNode = AstTestFactory.prefixExpression(
        TokenType.PLUS_PLUS, AstTestFactory.identifier3("x"));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticElement, same(staticElement));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitPropertyAccess() {
    var fromNode =
        AstTestFactory.propertyAccess2(AstTestFactory.identifier3("x"), "y");
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;
    PropertyAccess toNode =
        AstTestFactory.propertyAccess2(AstTestFactory.identifier3("x"), "y");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticType, same(staticType));
  }

  void test_visitRedirectingConstructorInvocation() {
    var fromNode = AstTestFactory.redirectingConstructorInvocation();
    ConstructorElement staticElement = ElementFactory.constructorElement2(
        ElementFactory.classElement2("C"), null);
    fromNode.staticElement = staticElement;
    RedirectingConstructorInvocation toNode =
        AstTestFactory.redirectingConstructorInvocation();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticElement, same(staticElement));
  }

  void test_visitRethrowExpression() {
    var fromNode = AstTestFactory.rethrowExpression();
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;
    RethrowExpression toNode = AstTestFactory.rethrowExpression();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticType, same(staticType));
  }

  void test_visitSetOrMapLiteral_map() {
    SetOrMapLiteralImpl createNode() => astFactory.setOrMapLiteral(
          typeArguments: AstTestFactory.typeArgumentList(
              [AstTestFactory.typeName4('A'), AstTestFactory.typeName4('B')]),
          leftBracket: TokenFactory.tokenFromType(TokenType.OPEN_CURLY_BRACKET),
          elements: [AstTestFactory.mapLiteralEntry3('c', 'd')],
          rightBracket:
              TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET),
        );

    DartType typeA = interfaceTypeStar(ElementFactory.classElement2('A'));
    DartType typeB = interfaceTypeStar(ElementFactory.classElement2('B'));
    DartType typeC = interfaceTypeStar(ElementFactory.classElement2('C'));
    DartType typeD = interfaceTypeStar(ElementFactory.classElement2('D'));

    SetOrMapLiteral fromNode = createNode();
    (fromNode.typeArguments!.arguments[0] as TypeNameImpl).type = typeA;
    (fromNode.typeArguments!.arguments[1] as TypeNameImpl).type = typeB;
    MapLiteralEntry fromEntry = fromNode.elements[0] as MapLiteralEntry;
    (fromEntry.key as SimpleStringLiteralImpl).staticType = typeC;
    (fromEntry.value as SimpleStringLiteralImpl).staticType = typeD;

    SetOrMapLiteral toNode = createNode();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect((toNode.typeArguments!.arguments[0] as TypeName).type, same(typeA));
    expect((toNode.typeArguments!.arguments[1] as TypeName).type, same(typeB));
    MapLiteralEntry toEntry = fromNode.elements[0] as MapLiteralEntry;
    expect((toEntry.key as SimpleStringLiteral).staticType, same(typeC));
    expect((toEntry.value as SimpleStringLiteral).staticType, same(typeD));
  }

  void test_visitSetOrMapLiteral_set() {
    SetOrMapLiteralImpl createNode() => astFactory.setOrMapLiteral(
          typeArguments:
              AstTestFactory.typeArgumentList([AstTestFactory.typeName4('A')]),
          leftBracket: TokenFactory.tokenFromType(TokenType.OPEN_CURLY_BRACKET),
          elements: [AstTestFactory.identifier3('b')],
          rightBracket:
              TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET),
        );

    DartType typeA = interfaceTypeStar(ElementFactory.classElement2('A'));
    DartType typeB = interfaceTypeStar(ElementFactory.classElement2('B'));

    SetOrMapLiteral fromNode = createNode();
    (fromNode.typeArguments!.arguments[0] as TypeNameImpl).type = typeA;
    (fromNode.elements[0] as SimpleIdentifierImpl).staticType = typeB;

    SetOrMapLiteral toNode = createNode();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect((toNode.typeArguments!.arguments[0] as TypeName).type, same(typeA));
    expect((toNode.elements[0] as SimpleIdentifier).staticType, same(typeB));
  }

  void test_visitSimpleIdentifier() {
    var fromNode = AstTestFactory.identifier3("x");
    MethodElement staticElement = ElementFactory.methodElement(
        "m", interfaceTypeStar(ElementFactory.classElement2('C')));
    fromNode.staticElement = staticElement;
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;
    SimpleIdentifier toNode = AstTestFactory.identifier3("x");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticElement, same(staticElement));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitSimpleStringLiteral() {
    var fromNode = AstTestFactory.string2("abc");
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;
    SimpleStringLiteral toNode = AstTestFactory.string2("abc");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticType, same(staticType));
  }

  void test_visitSpreadElement() {
    SpreadElement createNode() => astFactory.spreadElement(
        spreadOperator:
            TokenFactory.tokenFromType(TokenType.PERIOD_PERIOD_PERIOD),
        expression: astFactory.listLiteral(
            null,
            null,
            TokenFactory.tokenFromType(TokenType.OPEN_SQUARE_BRACKET),
            [AstTestFactory.identifier3('a')],
            TokenFactory.tokenFromType(TokenType.CLOSE_SQUARE_BRACKET)));

    DartType typeA = interfaceTypeStar(ElementFactory.classElement2('A'));

    SpreadElement fromNode = createNode();
    ((fromNode.expression as ListLiteral).elements[0] as SimpleIdentifierImpl)
        .staticType = typeA;

    SpreadElement toNode = createNode();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(
        ((toNode.expression as ListLiteral).elements[0] as SimpleIdentifier)
            .staticType,
        same(typeA));
  }

  void test_visitStringInterpolation() {
    var fromNode =
        AstTestFactory.string([AstTestFactory.interpolationString("a", "'a'")]);
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;
    StringInterpolation toNode =
        AstTestFactory.string([AstTestFactory.interpolationString("a", "'a'")]);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticType, same(staticType));
  }

  void test_visitSuperConstructorInvocation() {
    var fromNode = AstTestFactory.superConstructorInvocation();
    ConstructorElement staticElement = ElementFactory.constructorElement2(
        ElementFactory.classElement2("C"), null);
    fromNode.staticElement = staticElement;
    SuperConstructorInvocation toNode =
        AstTestFactory.superConstructorInvocation();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticElement, same(staticElement));
  }

  void test_visitSuperExpression() {
    var fromNode = AstTestFactory.superExpression();
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;
    SuperExpression toNode = AstTestFactory.superExpression();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticType, same(staticType));
  }

  void test_visitSymbolLiteral() {
    var fromNode = AstTestFactory.symbolLiteral(["s"]);
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;
    SymbolLiteral toNode = AstTestFactory.symbolLiteral(["s"]);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticType, same(staticType));
  }

  void test_visitThisExpression() {
    var fromNode = AstTestFactory.thisExpression();
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;
    ThisExpression toNode = AstTestFactory.thisExpression();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticType, same(staticType));
  }

  void test_visitThrowExpression() {
    var fromNode = AstTestFactory.throwExpression2(
      AstTestFactory.integer(0),
    );
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;
    ThrowExpression toNode = AstTestFactory.throwExpression2(
      AstTestFactory.integer(0),
    );
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticType, same(staticType));
  }

  void test_visitTypeName() {
    var fromNode = AstTestFactory.typeName4("C");
    DartType type = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.type = type;
    TypeName toNode = AstTestFactory.typeName4("C");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.type, same(type));
  }

  void _copyAndVerifyInvocation(
      InvocationExpressionImpl fromNode, InvocationExpression toNode) {
    DartType staticType = interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticType = staticType;

    DartType staticInvokeType =
        interfaceTypeStar(ElementFactory.classElement2('C'));
    fromNode.staticInvokeType = staticInvokeType;

    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticType, same(staticType));
    expect(toNode.staticInvokeType, same(staticInvokeType));
    List<TypeAnnotation> fromTypeArguments = toNode.typeArguments!.arguments;
    List<TypeAnnotation> toTypeArguments = fromNode.typeArguments!.arguments;
    for (int i = 0; i < fromTypeArguments.length; i++) {
      TypeAnnotation toArgument = fromTypeArguments[i];
      TypeAnnotation fromArgument = toTypeArguments[i];
      expect(toArgument.type, same(fromArgument.type));
    }
  }
}

class _AnalysisContextMock implements AnalysisContext {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AnalysisSessionMock implements AnalysisSession {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
