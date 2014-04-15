// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.protocol;

import 'dart:convert';

import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart';

import 'declarative_tests.dart';

main() {
  addTestSuite(NotificationTest);
  addTestSuite(RequestTest);
  addTestSuite(RequestErrorTest);
  addTestSuite(ResponseTest);
}

class NotificationTest {
  @runTest
  static void getParameter_defined() {
    Notification notification = new Notification('foo');
    notification.setParameter('x', 'y');
    expect(notification.event, equals('foo'));
    expect(notification.params.length, equals(1));
    expect(notification.getParameter('x'), equals('y'));
    expect(notification.toJson(), equals({
      'event' : 'foo',
      'params' : {'x' : 'y'}
    }));
  }

  @runTest
  static void getParameter_undefined() {
    Notification notification = new Notification('foo');
    expect(notification.event, equals('foo'));
    expect(notification.params.length, equals(0));
    expect(notification.getParameter('x'), isNull);
    expect(notification.toJson(), equals({
      'event' : 'foo'
    }));
  }

  @runTest
  static void fromJson() {
    Notification original = new Notification('foo');
    Notification notification = new Notification.fromJson(original.toJson());
    expect(notification.event, equals('foo'));
    expect(notification.params.length, equals(0));
    expect(notification.getParameter('x'), isNull);
  }

  @runTest
  static void fromJson_withParams() {
    Notification original = new Notification('foo');
    original.setParameter('x', 'y');
    Notification notification = new Notification.fromJson(original.toJson());
    expect(notification.event, equals('foo'));
    expect(notification.params.length, equals(1));
    expect(notification.getParameter('x'), equals('y'));
  }
}

class RequestTest {
  @runTest
  static void getParameter_defined() {
    String name = 'name';
    String value = 'value';
    Request request = new Request('0', '');
    request.setParameter(name, value);
    expect(request.getParameter(name), equals(value));
  }

  @runTest
  static void getParameter_undefined() {
    String name = 'name';
    Request request = new Request('0', '');
    expect(request.getParameter(name), isNull);
  }

  @runTest
  static void getRequiredParameter_defined() {
    String name = 'name';
    String value = 'value';
    Request request = new Request('0', '');
    request.setParameter(name, value);
    expect(request.getRequiredParameter(name), equals(value));
  }

  @runTest
  static void getRequiredParameter_undefined() {
    String name = 'name';
    Request request = new Request('0', '');
    expect(() => request.getRequiredParameter(name), _throwsRequestFailure);
  }

  @runTest
  static void fromJson() {
    Request original = new Request('one', 'aMethod');
    String json = JSON.encode(original.toJson());
    Request request = new Request.fromString(json);
    expect(request.id, equals('one'));
    expect(request.method, equals('aMethod'));
  }

  @runTest
  static void fromJson_invalidId() {
    String json = '{"id":{"one":"two"},"method":"aMethod","params":{"foo":"bar"}}';
    Request request = new Request.fromString(json);
    expect(request, isNull);
  }

  @runTest
  static void fromJson_invalidMethod() {
    String json = '{"id":"one","method":{"boo":"aMethod"},"params":{"foo":"bar"}}';
    Request request = new Request.fromString(json);
    expect(request, isNull);
  }

  @runTest
  static void fromJson_invalidParams() {
    String json = '{"id":"one","method":"aMethod","params":"foobar"}';
    Request request = new Request.fromString(json);
    expect(request, isNull);
  }

  @runTest
  static void fromJson_withParams() {
    Request original = new Request('one', 'aMethod');
    original.setParameter('foo', 'bar');
    String json = JSON.encode(original.toJson());
    Request request = new Request.fromString(json);
    expect(request.id, equals('one'));
    expect(request.method, equals('aMethod'));
    expect(request.getParameter('foo'), equals('bar'));
  }

  @runTest
  static void toBool() {
    Request request = new Request('0', '');
    expect(request.toBool(true), isTrue);
    expect(request.toBool(false), isFalse);
    expect(request.toBool('true'), isTrue);
    expect(request.toBool('false'), isFalse);
    expect(request.toBool('abc'), isFalse);
    expect(() => request.toBool(42), _throwsRequestFailure);
  }

  @runTest
  static void toInt() {
    Request request = new Request('0', '');
    expect(request.toInt(1), equals(1));
    expect(request.toInt('2'), equals(2));
    expect(() => request.toInt('xxx'), _throwsRequestFailure);
    expect(() => request.toInt(request), _throwsRequestFailure);
  }

  @runTest
  static void toJson() {
    Request request = new Request('one', 'aMethod');
    expect(request.toJson(), equals({
      Request.ID : 'one',
      Request.METHOD : 'aMethod'
    }));
  }

  @runTest
  static void toJson_withParams() {
    Request request = new Request('one', 'aMethod');
    request.setParameter('foo', 'bar');
    expect(request.toJson(), equals({
      Request.ID : 'one',
      Request.METHOD : 'aMethod',
      Request.PARAMS : {'foo' : 'bar'}
    }));
  }
}

class RequestErrorTest {
  @runTest
  static void create() {
    RequestError error = new RequestError(42, 'msg');
    expect(error.code, 42);
    expect(error.message, "msg");
    expect(error.toJson(), equals({
      RequestError.CODE: 42,
      RequestError.MESSAGE: "msg"
    }));
  }

  @runTest
  static void create_parseError() {
    RequestError error = new RequestError.parseError();
    expect(error.code, RequestError.CODE_PARSE_ERROR);
    expect(error.message, "Parse error");
  }

  @runTest
  static void create_methodNotFound() {
    RequestError error = new RequestError.methodNotFound();
    expect(error.code, RequestError.CODE_METHOD_NOT_FOUND);
    expect(error.message, "Method not found");
  }

  @runTest
  static void create_invalidParameters() {
    RequestError error = new RequestError.invalidParameters();
    expect(error.code, RequestError.CODE_INVALID_PARAMS);
    expect(error.message, "Invalid parameters");
  }

  @runTest
  static void create_invalidRequest() {
    RequestError error = new RequestError.invalidRequest();
    expect(error.code, RequestError.CODE_INVALID_REQUEST);
    expect(error.message, "Invalid request");
  }

  @runTest
  static void create_internalError() {
    RequestError error = new RequestError.internalError();
    expect(error.code, RequestError.CODE_INTERNAL_ERROR);
    expect(error.message, "Internal error");
  }

  @runTest
  static void create_serverAlreadyStarted() {
    RequestError error = new RequestError.serverAlreadyStarted();
    expect(error.code, RequestError.CODE_SERVER_ALREADY_STARTED);
    expect(error.message, "Server already started");
  }

  @runTest
  static void fromJson() {
    var json = {
        RequestError.CODE: RequestError.CODE_PARSE_ERROR,
        RequestError.MESSAGE: 'foo',
        RequestError.DATA: {'ints': [1, 2, 3]}
    };
    RequestError error = new RequestError.fromJson(json);
    expect(error.code, RequestError.CODE_PARSE_ERROR);
    expect(error.message, "foo");
    expect(error.data['ints'], [1, 2, 3]);
    expect(error.getData('ints'), [1, 2, 3]);
  }

  @runTest
  static void toJson() {
    RequestError error = new RequestError(0, 'msg');
    error.setData('answer', 42);
    error.setData('question', 'unknown');
    expect(error.toJson(), {
        RequestError.CODE: 0,
        RequestError.MESSAGE: 'msg',
        RequestError.DATA: {'answer': 42, 'question': 'unknown'}
    });
  }
}

class ResponseTest {
  @runTest
  static void create_contextDoesNotExist() {
    Response response = new Response.contextDoesNotExist(new Request('0', ''));
    expect(response.id, equals('0'));
    expect(response.error, isNotNull);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: {'code': -1, 'message': 'Context does not exist'}
    }));
  }

  @runTest
  static void create_invalidRequestFormat() {
    Response response = new Response.invalidRequestFormat();
    expect(response.id, equals(''));
    expect(response.error, isNotNull);
    expect(response.toJson(), equals({
      Response.ID: '',
      Response.ERROR: {'code': -4, 'message': 'Invalid request'}
    }));
  }

  @runTest
  static void create_missingRequiredParameter() {
    Response response = new Response.missingRequiredParameter(new Request('0', ''), 'x');
    expect(response.id, equals('0'));
    expect(response.error, isNotNull);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: {'code': -5, 'message': 'Missing required parameter: x'}
    }));
  }

  @runTest
  static void create_unknownAnalysisOption() {
    Response response = new Response.unknownAnalysisOption(new Request('0', ''), 'x');
    expect(response.id, equals('0'));
    expect(response.error, isNotNull);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: {'code': -6, 'message': 'Unknown analysis option: "x"'}
    }));
  }

  @runTest
  static void create_unknownRequest() {
    Response response = new Response.unknownRequest(new Request('0', ''));
    expect(response.id, equals('0'));
    expect(response.error, isNotNull);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: {'code': -7, 'message': 'Unknown request'}
    }));
  }

  @runTest
  static void setResult() {
    String resultName = 'name';
    String resultValue = 'value';
    Response response = new Response('0');
    response.setResult(resultName, resultValue);
    expect(response.getResult(resultName), same(resultValue));
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: null,
      Response.RESULT: {
        resultName: resultValue
      }
    }));
  }

  @runTest
  static void fromJson() {
    Response original = new Response('myId');
    Response response = new Response.fromJson(original.toJson());
    expect(response.id, equals('myId'));
  }

  @runTest
  static void fromJson_withError() {
    Response original = new Response.invalidRequestFormat();
    Response response = new Response.fromJson(original.toJson());
    expect(response.id, equals(''));
    expect(response.error, isNotNull);
    RequestError error = response.error;
    expect(error.code, equals(-4));
    expect(error.message, equals('Invalid request'));
  }

  @runTest
  static void fromJson_withResult() {
    Response original = new Response('myId');
    original.setResult('foo', 'bar');
    Response response = new Response.fromJson(original.toJson());
    expect(response.id, equals('myId'));
    Map<String, Object> result = response.result;
    expect(result.length, equals(1));
    expect(result['foo'], equals('bar'));
  }
}

Matcher _throwsRequestFailure = throwsA(new isInstanceOf<RequestFailure>());
