// Generated from Apache PDFBox library which is licensed under the Apache License 2.0.
// The following copyright from the original authors applies.
//
// Licensed to the Apache Software Foundation (ASF) under one or more
// contributor license agreements.  See the NOTICE file distributed with
// this work for additional information regarding copyright ownership.
// The ASF licenses this file to You under the Apache License, Version 2.0
// (the "License"); you may not use this file except in compliance with
// the License.  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Autogenerated by jnigen. DO NOT EDIT!

// ignore_for_file: annotate_overrides
// ignore_for_file: argument_type_not_assignable
// ignore_for_file: camel_case_extensions
// ignore_for_file: camel_case_types
// ignore_for_file: constant_identifier_names
// ignore_for_file: doc_directive_unknown
// ignore_for_file: file_names
// ignore_for_file: inference_failure_on_untyped_parameter
// ignore_for_file: invalid_internal_annotation
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: library_prefixes
// ignore_for_file: lines_longer_than_80_chars
// ignore_for_file: no_leading_underscores_for_library_prefixes
// ignore_for_file: no_leading_underscores_for_local_identifiers
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: only_throw_errors
// ignore_for_file: overridden_fields
// ignore_for_file: prefer_double_quotes
// ignore_for_file: unintended_html_in_doc_comment
// ignore_for_file: unnecessary_cast
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: unused_element
// ignore_for_file: unused_field
// ignore_for_file: unused_import
// ignore_for_file: unused_local_variable
// ignore_for_file: unused_shown_name
// ignore_for_file: use_super_parameters

import 'dart:core' show Object, String, bool, double, int;
import 'dart:core' as _$core;

import 'package:jni/_internal.dart' as _$jni;
import 'package:jni/jni.dart' as _$jni;

/// from: `org.apache.pdfbox.pdmodel.PDDocumentInformation`
///
/// This is the document metadata.  Each getXXX method will return the entry if
/// it exists or null if it does not exist.  If you pass in null for the setXXX
/// method then it will clear the value.
///@author Ben Litchfield
///@author Gerardo Ortiz
class PDDocumentInformation extends _$jni.JObject {
  @_$jni.internal
  @_$core.override
  final _$jni.JObjType<PDDocumentInformation> $type;

  @_$jni.internal
  PDDocumentInformation.fromReference(
    _$jni.JReference reference,
  )   : $type = type,
        super.fromReference(reference);

  static final _class =
      _$jni.JClass.forName(r'org/apache/pdfbox/pdmodel/PDDocumentInformation');

  /// The type which includes information such as the signature of this class.
  static const nullableType = $PDDocumentInformation$NullableType();
  static const type = $PDDocumentInformation$Type();
  static final _id_new$ = _class.constructorId(
    r'()V',
  );

  static final _new$ = _$jni.ProtectedJniExtensions.lookup<
          _$jni.NativeFunction<
              _$jni.JniResult Function(
                _$jni.Pointer<_$jni.Void>,
                _$jni.JMethodIDPtr,
              )>>('globalEnv_NewObject')
      .asFunction<
          _$jni.JniResult Function(
            _$jni.Pointer<_$jni.Void>,
            _$jni.JMethodIDPtr,
          )>();

  /// from: `public void <init>()`
  /// The returned object must be released after use, by calling the [release] method.
  ///
  /// Default Constructor.
  factory PDDocumentInformation() {
    return PDDocumentInformation.fromReference(
        _new$(_class.reference.pointer, _id_new$ as _$jni.JMethodIDPtr)
            .reference);
  }

  static final _id_new$1 = _class.constructorId(
    r'(Lorg/apache/pdfbox/cos/COSDictionary;)V',
  );

  static final _new$1 = _$jni.ProtectedJniExtensions.lookup<
              _$jni.NativeFunction<
                  _$jni.JniResult Function(
                      _$jni.Pointer<_$jni.Void>,
                      _$jni.JMethodIDPtr,
                      _$jni.VarArgs<(_$jni.Pointer<_$jni.Void>,)>)>>(
          'globalEnv_NewObject')
      .asFunction<
          _$jni.JniResult Function(_$jni.Pointer<_$jni.Void>,
              _$jni.JMethodIDPtr, _$jni.Pointer<_$jni.Void>)>();

  /// from: `public void <init>(org.apache.pdfbox.cos.COSDictionary dic)`
  /// The returned object must be released after use, by calling the [release] method.
  ///
  /// Constructor that is used for a preexisting dictionary.
  ///@param dic The underlying dictionary.
  factory PDDocumentInformation.new$1(
    _$jni.JObject? dic,
  ) {
    final _dic = dic?.reference ?? _$jni.jNullReference;
    return PDDocumentInformation.fromReference(_new$1(_class.reference.pointer,
            _id_new$1 as _$jni.JMethodIDPtr, _dic.pointer)
        .reference);
  }

  static final _id_getCOSObject = _class.instanceMethodId(
    r'getCOSObject',
    r'()Lorg/apache/pdfbox/cos/COSDictionary;',
  );

  static final _getCOSObject = _$jni.ProtectedJniExtensions.lookup<
          _$jni.NativeFunction<
              _$jni.JniResult Function(
                _$jni.Pointer<_$jni.Void>,
                _$jni.JMethodIDPtr,
              )>>('globalEnv_CallObjectMethod')
      .asFunction<
          _$jni.JniResult Function(
            _$jni.Pointer<_$jni.Void>,
            _$jni.JMethodIDPtr,
          )>();

  /// from: `public org.apache.pdfbox.cos.COSDictionary getCOSObject()`
  /// The returned object must be released after use, by calling the [release] method.
  ///
  /// This will get the underlying dictionary that this object wraps.
  ///@return The underlying info dictionary.
  _$jni.JObject? getCOSObject() {
    return _getCOSObject(
            reference.pointer, _id_getCOSObject as _$jni.JMethodIDPtr)
        .object(const _$jni.JObjectNullableType());
  }

  static final _id_getPropertyStringValue = _class.instanceMethodId(
    r'getPropertyStringValue',
    r'(Ljava/lang/String;)Ljava/lang/Object;',
  );

  static final _getPropertyStringValue = _$jni.ProtectedJniExtensions.lookup<
              _$jni.NativeFunction<
                  _$jni.JniResult Function(
                      _$jni.Pointer<_$jni.Void>,
                      _$jni.JMethodIDPtr,
                      _$jni.VarArgs<(_$jni.Pointer<_$jni.Void>,)>)>>(
          'globalEnv_CallObjectMethod')
      .asFunction<
          _$jni.JniResult Function(_$jni.Pointer<_$jni.Void>,
              _$jni.JMethodIDPtr, _$jni.Pointer<_$jni.Void>)>();

  /// from: `public java.lang.Object getPropertyStringValue(java.lang.String propertyKey)`
  /// The returned object must be released after use, by calling the [release] method.
  ///
  /// Return the properties String value.
  ///
  /// Allows to retrieve the
  /// low level date for validation purposes.
  ///
  ///
  ///@param propertyKey the dictionaries key
  ///@return the properties value
  _$jni.JObject? getPropertyStringValue(
    _$jni.JString? propertyKey,
  ) {
    final _propertyKey = propertyKey?.reference ?? _$jni.jNullReference;
    return _getPropertyStringValue(
            reference.pointer,
            _id_getPropertyStringValue as _$jni.JMethodIDPtr,
            _propertyKey.pointer)
        .object(const _$jni.JObjectNullableType());
  }

  static final _id_getTitle = _class.instanceMethodId(
    r'getTitle',
    r'()Ljava/lang/String;',
  );

  static final _getTitle = _$jni.ProtectedJniExtensions.lookup<
          _$jni.NativeFunction<
              _$jni.JniResult Function(
                _$jni.Pointer<_$jni.Void>,
                _$jni.JMethodIDPtr,
              )>>('globalEnv_CallObjectMethod')
      .asFunction<
          _$jni.JniResult Function(
            _$jni.Pointer<_$jni.Void>,
            _$jni.JMethodIDPtr,
          )>();

  /// from: `public java.lang.String getTitle()`
  /// The returned object must be released after use, by calling the [release] method.
  ///
  /// This will get the title of the document.  This will return null if no title exists.
  ///@return The title of the document.
  _$jni.JString? getTitle() {
    return _getTitle(reference.pointer, _id_getTitle as _$jni.JMethodIDPtr)
        .object(const _$jni.JStringNullableType());
  }

  static final _id_setTitle = _class.instanceMethodId(
    r'setTitle',
    r'(Ljava/lang/String;)V',
  );

  static final _setTitle = _$jni.ProtectedJniExtensions.lookup<
              _$jni.NativeFunction<
                  _$jni.JThrowablePtr Function(
                      _$jni.Pointer<_$jni.Void>,
                      _$jni.JMethodIDPtr,
                      _$jni.VarArgs<(_$jni.Pointer<_$jni.Void>,)>)>>(
          'globalEnv_CallVoidMethod')
      .asFunction<
          _$jni.JThrowablePtr Function(_$jni.Pointer<_$jni.Void>,
              _$jni.JMethodIDPtr, _$jni.Pointer<_$jni.Void>)>();

  /// from: `public void setTitle(java.lang.String title)`
  ///
  /// This will set the title of the document.
  ///@param title The new title for the document.
  void setTitle(
    _$jni.JString? title,
  ) {
    final _title = title?.reference ?? _$jni.jNullReference;
    _setTitle(reference.pointer, _id_setTitle as _$jni.JMethodIDPtr,
            _title.pointer)
        .check();
  }

  static final _id_getAuthor = _class.instanceMethodId(
    r'getAuthor',
    r'()Ljava/lang/String;',
  );

  static final _getAuthor = _$jni.ProtectedJniExtensions.lookup<
          _$jni.NativeFunction<
              _$jni.JniResult Function(
                _$jni.Pointer<_$jni.Void>,
                _$jni.JMethodIDPtr,
              )>>('globalEnv_CallObjectMethod')
      .asFunction<
          _$jni.JniResult Function(
            _$jni.Pointer<_$jni.Void>,
            _$jni.JMethodIDPtr,
          )>();

  /// from: `public java.lang.String getAuthor()`
  /// The returned object must be released after use, by calling the [release] method.
  ///
  /// This will get the author of the document.  This will return null if no author exists.
  ///@return The author of the document.
  _$jni.JString? getAuthor() {
    return _getAuthor(reference.pointer, _id_getAuthor as _$jni.JMethodIDPtr)
        .object(const _$jni.JStringNullableType());
  }

  static final _id_setAuthor = _class.instanceMethodId(
    r'setAuthor',
    r'(Ljava/lang/String;)V',
  );

  static final _setAuthor = _$jni.ProtectedJniExtensions.lookup<
              _$jni.NativeFunction<
                  _$jni.JThrowablePtr Function(
                      _$jni.Pointer<_$jni.Void>,
                      _$jni.JMethodIDPtr,
                      _$jni.VarArgs<(_$jni.Pointer<_$jni.Void>,)>)>>(
          'globalEnv_CallVoidMethod')
      .asFunction<
          _$jni.JThrowablePtr Function(_$jni.Pointer<_$jni.Void>,
              _$jni.JMethodIDPtr, _$jni.Pointer<_$jni.Void>)>();

  /// from: `public void setAuthor(java.lang.String author)`
  ///
  /// This will set the author of the document.
  ///@param author The new author for the document.
  void setAuthor(
    _$jni.JString? author,
  ) {
    final _author = author?.reference ?? _$jni.jNullReference;
    _setAuthor(reference.pointer, _id_setAuthor as _$jni.JMethodIDPtr,
            _author.pointer)
        .check();
  }

  static final _id_getSubject = _class.instanceMethodId(
    r'getSubject',
    r'()Ljava/lang/String;',
  );

  static final _getSubject = _$jni.ProtectedJniExtensions.lookup<
          _$jni.NativeFunction<
              _$jni.JniResult Function(
                _$jni.Pointer<_$jni.Void>,
                _$jni.JMethodIDPtr,
              )>>('globalEnv_CallObjectMethod')
      .asFunction<
          _$jni.JniResult Function(
            _$jni.Pointer<_$jni.Void>,
            _$jni.JMethodIDPtr,
          )>();

  /// from: `public java.lang.String getSubject()`
  /// The returned object must be released after use, by calling the [release] method.
  ///
  /// This will get the subject of the document.  This will return null if no subject exists.
  ///@return The subject of the document.
  _$jni.JString? getSubject() {
    return _getSubject(reference.pointer, _id_getSubject as _$jni.JMethodIDPtr)
        .object(const _$jni.JStringNullableType());
  }

  static final _id_setSubject = _class.instanceMethodId(
    r'setSubject',
    r'(Ljava/lang/String;)V',
  );

  static final _setSubject = _$jni.ProtectedJniExtensions.lookup<
              _$jni.NativeFunction<
                  _$jni.JThrowablePtr Function(
                      _$jni.Pointer<_$jni.Void>,
                      _$jni.JMethodIDPtr,
                      _$jni.VarArgs<(_$jni.Pointer<_$jni.Void>,)>)>>(
          'globalEnv_CallVoidMethod')
      .asFunction<
          _$jni.JThrowablePtr Function(_$jni.Pointer<_$jni.Void>,
              _$jni.JMethodIDPtr, _$jni.Pointer<_$jni.Void>)>();

  /// from: `public void setSubject(java.lang.String subject)`
  ///
  /// This will set the subject of the document.
  ///@param subject The new subject for the document.
  void setSubject(
    _$jni.JString? subject,
  ) {
    final _subject = subject?.reference ?? _$jni.jNullReference;
    _setSubject(reference.pointer, _id_setSubject as _$jni.JMethodIDPtr,
            _subject.pointer)
        .check();
  }

  static final _id_getKeywords = _class.instanceMethodId(
    r'getKeywords',
    r'()Ljava/lang/String;',
  );

  static final _getKeywords = _$jni.ProtectedJniExtensions.lookup<
          _$jni.NativeFunction<
              _$jni.JniResult Function(
                _$jni.Pointer<_$jni.Void>,
                _$jni.JMethodIDPtr,
              )>>('globalEnv_CallObjectMethod')
      .asFunction<
          _$jni.JniResult Function(
            _$jni.Pointer<_$jni.Void>,
            _$jni.JMethodIDPtr,
          )>();

  /// from: `public java.lang.String getKeywords()`
  /// The returned object must be released after use, by calling the [release] method.
  ///
  /// This will get the keywords of the document.  This will return null if no keywords exists.
  ///@return The keywords of the document.
  _$jni.JString? getKeywords() {
    return _getKeywords(
            reference.pointer, _id_getKeywords as _$jni.JMethodIDPtr)
        .object(const _$jni.JStringNullableType());
  }

  static final _id_setKeywords = _class.instanceMethodId(
    r'setKeywords',
    r'(Ljava/lang/String;)V',
  );

  static final _setKeywords = _$jni.ProtectedJniExtensions.lookup<
              _$jni.NativeFunction<
                  _$jni.JThrowablePtr Function(
                      _$jni.Pointer<_$jni.Void>,
                      _$jni.JMethodIDPtr,
                      _$jni.VarArgs<(_$jni.Pointer<_$jni.Void>,)>)>>(
          'globalEnv_CallVoidMethod')
      .asFunction<
          _$jni.JThrowablePtr Function(_$jni.Pointer<_$jni.Void>,
              _$jni.JMethodIDPtr, _$jni.Pointer<_$jni.Void>)>();

  /// from: `public void setKeywords(java.lang.String keywords)`
  ///
  /// This will set the keywords of the document.
  ///@param keywords The new keywords for the document.
  void setKeywords(
    _$jni.JString? keywords,
  ) {
    final _keywords = keywords?.reference ?? _$jni.jNullReference;
    _setKeywords(reference.pointer, _id_setKeywords as _$jni.JMethodIDPtr,
            _keywords.pointer)
        .check();
  }

  static final _id_getCreator = _class.instanceMethodId(
    r'getCreator',
    r'()Ljava/lang/String;',
  );

  static final _getCreator = _$jni.ProtectedJniExtensions.lookup<
          _$jni.NativeFunction<
              _$jni.JniResult Function(
                _$jni.Pointer<_$jni.Void>,
                _$jni.JMethodIDPtr,
              )>>('globalEnv_CallObjectMethod')
      .asFunction<
          _$jni.JniResult Function(
            _$jni.Pointer<_$jni.Void>,
            _$jni.JMethodIDPtr,
          )>();

  /// from: `public java.lang.String getCreator()`
  /// The returned object must be released after use, by calling the [release] method.
  ///
  /// This will get the creator of the document.  This will return null if no creator exists.
  ///@return The creator of the document.
  _$jni.JString? getCreator() {
    return _getCreator(reference.pointer, _id_getCreator as _$jni.JMethodIDPtr)
        .object(const _$jni.JStringNullableType());
  }

  static final _id_setCreator = _class.instanceMethodId(
    r'setCreator',
    r'(Ljava/lang/String;)V',
  );

  static final _setCreator = _$jni.ProtectedJniExtensions.lookup<
              _$jni.NativeFunction<
                  _$jni.JThrowablePtr Function(
                      _$jni.Pointer<_$jni.Void>,
                      _$jni.JMethodIDPtr,
                      _$jni.VarArgs<(_$jni.Pointer<_$jni.Void>,)>)>>(
          'globalEnv_CallVoidMethod')
      .asFunction<
          _$jni.JThrowablePtr Function(_$jni.Pointer<_$jni.Void>,
              _$jni.JMethodIDPtr, _$jni.Pointer<_$jni.Void>)>();

  /// from: `public void setCreator(java.lang.String creator)`
  ///
  /// This will set the creator of the document.
  ///@param creator The new creator for the document.
  void setCreator(
    _$jni.JString? creator,
  ) {
    final _creator = creator?.reference ?? _$jni.jNullReference;
    _setCreator(reference.pointer, _id_setCreator as _$jni.JMethodIDPtr,
            _creator.pointer)
        .check();
  }

  static final _id_getProducer = _class.instanceMethodId(
    r'getProducer',
    r'()Ljava/lang/String;',
  );

  static final _getProducer = _$jni.ProtectedJniExtensions.lookup<
          _$jni.NativeFunction<
              _$jni.JniResult Function(
                _$jni.Pointer<_$jni.Void>,
                _$jni.JMethodIDPtr,
              )>>('globalEnv_CallObjectMethod')
      .asFunction<
          _$jni.JniResult Function(
            _$jni.Pointer<_$jni.Void>,
            _$jni.JMethodIDPtr,
          )>();

  /// from: `public java.lang.String getProducer()`
  /// The returned object must be released after use, by calling the [release] method.
  ///
  /// This will get the producer of the document.  This will return null if no producer exists.
  ///@return The producer of the document.
  _$jni.JString? getProducer() {
    return _getProducer(
            reference.pointer, _id_getProducer as _$jni.JMethodIDPtr)
        .object(const _$jni.JStringNullableType());
  }

  static final _id_setProducer = _class.instanceMethodId(
    r'setProducer',
    r'(Ljava/lang/String;)V',
  );

  static final _setProducer = _$jni.ProtectedJniExtensions.lookup<
              _$jni.NativeFunction<
                  _$jni.JThrowablePtr Function(
                      _$jni.Pointer<_$jni.Void>,
                      _$jni.JMethodIDPtr,
                      _$jni.VarArgs<(_$jni.Pointer<_$jni.Void>,)>)>>(
          'globalEnv_CallVoidMethod')
      .asFunction<
          _$jni.JThrowablePtr Function(_$jni.Pointer<_$jni.Void>,
              _$jni.JMethodIDPtr, _$jni.Pointer<_$jni.Void>)>();

  /// from: `public void setProducer(java.lang.String producer)`
  ///
  /// This will set the producer of the document.
  ///@param producer The new producer for the document.
  void setProducer(
    _$jni.JString? producer,
  ) {
    final _producer = producer?.reference ?? _$jni.jNullReference;
    _setProducer(reference.pointer, _id_setProducer as _$jni.JMethodIDPtr,
            _producer.pointer)
        .check();
  }

  static final _id_getCreationDate = _class.instanceMethodId(
    r'getCreationDate',
    r'()Ljava/util/Calendar;',
  );

  static final _getCreationDate = _$jni.ProtectedJniExtensions.lookup<
          _$jni.NativeFunction<
              _$jni.JniResult Function(
                _$jni.Pointer<_$jni.Void>,
                _$jni.JMethodIDPtr,
              )>>('globalEnv_CallObjectMethod')
      .asFunction<
          _$jni.JniResult Function(
            _$jni.Pointer<_$jni.Void>,
            _$jni.JMethodIDPtr,
          )>();

  /// from: `public java.util.Calendar getCreationDate()`
  /// The returned object must be released after use, by calling the [release] method.
  ///
  /// This will get the creation date of the document.  This will return null if no creation date exists.
  ///@return The creation date of the document.
  _$jni.JObject? getCreationDate() {
    return _getCreationDate(
            reference.pointer, _id_getCreationDate as _$jni.JMethodIDPtr)
        .object(const _$jni.JObjectNullableType());
  }

  static final _id_setCreationDate = _class.instanceMethodId(
    r'setCreationDate',
    r'(Ljava/util/Calendar;)V',
  );

  static final _setCreationDate = _$jni.ProtectedJniExtensions.lookup<
              _$jni.NativeFunction<
                  _$jni.JThrowablePtr Function(
                      _$jni.Pointer<_$jni.Void>,
                      _$jni.JMethodIDPtr,
                      _$jni.VarArgs<(_$jni.Pointer<_$jni.Void>,)>)>>(
          'globalEnv_CallVoidMethod')
      .asFunction<
          _$jni.JThrowablePtr Function(_$jni.Pointer<_$jni.Void>,
              _$jni.JMethodIDPtr, _$jni.Pointer<_$jni.Void>)>();

  /// from: `public void setCreationDate(java.util.Calendar date)`
  ///
  /// This will set the creation date of the document.
  ///@param date The new creation date for the document.
  void setCreationDate(
    _$jni.JObject? date,
  ) {
    final _date = date?.reference ?? _$jni.jNullReference;
    _setCreationDate(reference.pointer,
            _id_setCreationDate as _$jni.JMethodIDPtr, _date.pointer)
        .check();
  }

  static final _id_getModificationDate = _class.instanceMethodId(
    r'getModificationDate',
    r'()Ljava/util/Calendar;',
  );

  static final _getModificationDate = _$jni.ProtectedJniExtensions.lookup<
          _$jni.NativeFunction<
              _$jni.JniResult Function(
                _$jni.Pointer<_$jni.Void>,
                _$jni.JMethodIDPtr,
              )>>('globalEnv_CallObjectMethod')
      .asFunction<
          _$jni.JniResult Function(
            _$jni.Pointer<_$jni.Void>,
            _$jni.JMethodIDPtr,
          )>();

  /// from: `public java.util.Calendar getModificationDate()`
  /// The returned object must be released after use, by calling the [release] method.
  ///
  /// This will get the modification date of the document.  This will return null if no modification date exists.
  ///@return The modification date of the document.
  _$jni.JObject? getModificationDate() {
    return _getModificationDate(
            reference.pointer, _id_getModificationDate as _$jni.JMethodIDPtr)
        .object(const _$jni.JObjectNullableType());
  }

  static final _id_setModificationDate = _class.instanceMethodId(
    r'setModificationDate',
    r'(Ljava/util/Calendar;)V',
  );

  static final _setModificationDate = _$jni.ProtectedJniExtensions.lookup<
              _$jni.NativeFunction<
                  _$jni.JThrowablePtr Function(
                      _$jni.Pointer<_$jni.Void>,
                      _$jni.JMethodIDPtr,
                      _$jni.VarArgs<(_$jni.Pointer<_$jni.Void>,)>)>>(
          'globalEnv_CallVoidMethod')
      .asFunction<
          _$jni.JThrowablePtr Function(_$jni.Pointer<_$jni.Void>,
              _$jni.JMethodIDPtr, _$jni.Pointer<_$jni.Void>)>();

  /// from: `public void setModificationDate(java.util.Calendar date)`
  ///
  /// This will set the modification date of the document.
  ///@param date The new modification date for the document.
  void setModificationDate(
    _$jni.JObject? date,
  ) {
    final _date = date?.reference ?? _$jni.jNullReference;
    _setModificationDate(reference.pointer,
            _id_setModificationDate as _$jni.JMethodIDPtr, _date.pointer)
        .check();
  }

  static final _id_getTrapped = _class.instanceMethodId(
    r'getTrapped',
    r'()Ljava/lang/String;',
  );

  static final _getTrapped = _$jni.ProtectedJniExtensions.lookup<
          _$jni.NativeFunction<
              _$jni.JniResult Function(
                _$jni.Pointer<_$jni.Void>,
                _$jni.JMethodIDPtr,
              )>>('globalEnv_CallObjectMethod')
      .asFunction<
          _$jni.JniResult Function(
            _$jni.Pointer<_$jni.Void>,
            _$jni.JMethodIDPtr,
          )>();

  /// from: `public java.lang.String getTrapped()`
  /// The returned object must be released after use, by calling the [release] method.
  ///
  /// This will get the trapped value for the document.
  /// This will return null if one is not found.
  ///@return The trapped value for the document.
  _$jni.JString? getTrapped() {
    return _getTrapped(reference.pointer, _id_getTrapped as _$jni.JMethodIDPtr)
        .object(const _$jni.JStringNullableType());
  }

  static final _id_getMetadataKeys = _class.instanceMethodId(
    r'getMetadataKeys',
    r'()Ljava/util/Set;',
  );

  static final _getMetadataKeys = _$jni.ProtectedJniExtensions.lookup<
          _$jni.NativeFunction<
              _$jni.JniResult Function(
                _$jni.Pointer<_$jni.Void>,
                _$jni.JMethodIDPtr,
              )>>('globalEnv_CallObjectMethod')
      .asFunction<
          _$jni.JniResult Function(
            _$jni.Pointer<_$jni.Void>,
            _$jni.JMethodIDPtr,
          )>();

  /// from: `public java.util.Set<java.lang.String> getMetadataKeys()`
  /// The returned object must be released after use, by calling the [release] method.
  ///
  /// This will get the keys of all metadata information fields for the document.
  ///@return all metadata key strings.
  ///@since Apache PDFBox 1.3.0
  _$jni.JSet<_$jni.JString?>? getMetadataKeys() {
    return _getMetadataKeys(
            reference.pointer, _id_getMetadataKeys as _$jni.JMethodIDPtr)
        .object(const _$jni.JSetNullableType(_$jni.JStringNullableType()));
  }

  static final _id_getCustomMetadataValue = _class.instanceMethodId(
    r'getCustomMetadataValue',
    r'(Ljava/lang/String;)Ljava/lang/String;',
  );

  static final _getCustomMetadataValue = _$jni.ProtectedJniExtensions.lookup<
              _$jni.NativeFunction<
                  _$jni.JniResult Function(
                      _$jni.Pointer<_$jni.Void>,
                      _$jni.JMethodIDPtr,
                      _$jni.VarArgs<(_$jni.Pointer<_$jni.Void>,)>)>>(
          'globalEnv_CallObjectMethod')
      .asFunction<
          _$jni.JniResult Function(_$jni.Pointer<_$jni.Void>,
              _$jni.JMethodIDPtr, _$jni.Pointer<_$jni.Void>)>();

  /// from: `public java.lang.String getCustomMetadataValue(java.lang.String fieldName)`
  /// The returned object must be released after use, by calling the [release] method.
  ///
  /// This will get the value of a custom metadata information field for the document.
  ///  This will return null if one is not found.
  ///@param fieldName Name of custom metadata field from pdf document.
  ///@return String Value of metadata field
  _$jni.JString? getCustomMetadataValue(
    _$jni.JString? fieldName,
  ) {
    final _fieldName = fieldName?.reference ?? _$jni.jNullReference;
    return _getCustomMetadataValue(
            reference.pointer,
            _id_getCustomMetadataValue as _$jni.JMethodIDPtr,
            _fieldName.pointer)
        .object(const _$jni.JStringNullableType());
  }

  static final _id_setCustomMetadataValue = _class.instanceMethodId(
    r'setCustomMetadataValue',
    r'(Ljava/lang/String;Ljava/lang/String;)V',
  );

  static final _setCustomMetadataValue = _$jni.ProtectedJniExtensions.lookup<
          _$jni.NativeFunction<
              _$jni.JThrowablePtr Function(
                  _$jni.Pointer<_$jni.Void>,
                  _$jni.JMethodIDPtr,
                  _$jni.VarArgs<
                      (
                        _$jni.Pointer<_$jni.Void>,
                        _$jni.Pointer<_$jni.Void>
                      )>)>>('globalEnv_CallVoidMethod')
      .asFunction<
          _$jni.JThrowablePtr Function(
              _$jni.Pointer<_$jni.Void>,
              _$jni.JMethodIDPtr,
              _$jni.Pointer<_$jni.Void>,
              _$jni.Pointer<_$jni.Void>)>();

  /// from: `public void setCustomMetadataValue(java.lang.String fieldName, java.lang.String fieldValue)`
  ///
  /// Set the custom metadata value.
  ///@param fieldName The name of the custom metadata field.
  ///@param fieldValue The value to the custom metadata field.
  void setCustomMetadataValue(
    _$jni.JString? fieldName,
    _$jni.JString? fieldValue,
  ) {
    final _fieldName = fieldName?.reference ?? _$jni.jNullReference;
    final _fieldValue = fieldValue?.reference ?? _$jni.jNullReference;
    _setCustomMetadataValue(
            reference.pointer,
            _id_setCustomMetadataValue as _$jni.JMethodIDPtr,
            _fieldName.pointer,
            _fieldValue.pointer)
        .check();
  }

  static final _id_setTrapped = _class.instanceMethodId(
    r'setTrapped',
    r'(Ljava/lang/String;)V',
  );

  static final _setTrapped = _$jni.ProtectedJniExtensions.lookup<
              _$jni.NativeFunction<
                  _$jni.JThrowablePtr Function(
                      _$jni.Pointer<_$jni.Void>,
                      _$jni.JMethodIDPtr,
                      _$jni.VarArgs<(_$jni.Pointer<_$jni.Void>,)>)>>(
          'globalEnv_CallVoidMethod')
      .asFunction<
          _$jni.JThrowablePtr Function(_$jni.Pointer<_$jni.Void>,
              _$jni.JMethodIDPtr, _$jni.Pointer<_$jni.Void>)>();

  /// from: `public void setTrapped(java.lang.String value)`
  ///
  /// This will set the trapped of the document.  This will be
  /// 'True', 'False', or 'Unknown'.
  ///@param value The new trapped value for the document.
  ///@throws IllegalArgumentException if the parameter is invalid.
  void setTrapped(
    _$jni.JString? value,
  ) {
    final _value = value?.reference ?? _$jni.jNullReference;
    _setTrapped(reference.pointer, _id_setTrapped as _$jni.JMethodIDPtr,
            _value.pointer)
        .check();
  }
}

final class $PDDocumentInformation$NullableType
    extends _$jni.JObjType<PDDocumentInformation?> {
  @_$jni.internal
  const $PDDocumentInformation$NullableType();

  @_$jni.internal
  @_$core.override
  String get signature => r'Lorg/apache/pdfbox/pdmodel/PDDocumentInformation;';

  @_$jni.internal
  @_$core.override
  PDDocumentInformation? fromReference(_$jni.JReference reference) =>
      reference.isNull
          ? null
          : PDDocumentInformation.fromReference(
              reference,
            );
  @_$jni.internal
  @_$core.override
  _$jni.JObjType get superType => const _$jni.JObjectNullableType();

  @_$jni.internal
  @_$core.override
  _$jni.JObjType<PDDocumentInformation?> get nullableType => this;

  @_$jni.internal
  @_$core.override
  final superCount = 1;

  @_$core.override
  int get hashCode => ($PDDocumentInformation$NullableType).hashCode;

  @_$core.override
  bool operator ==(Object other) {
    return other.runtimeType == ($PDDocumentInformation$NullableType) &&
        other is $PDDocumentInformation$NullableType;
  }
}

final class $PDDocumentInformation$Type
    extends _$jni.JObjType<PDDocumentInformation> {
  @_$jni.internal
  const $PDDocumentInformation$Type();

  @_$jni.internal
  @_$core.override
  String get signature => r'Lorg/apache/pdfbox/pdmodel/PDDocumentInformation;';

  @_$jni.internal
  @_$core.override
  PDDocumentInformation fromReference(_$jni.JReference reference) =>
      PDDocumentInformation.fromReference(
        reference,
      );
  @_$jni.internal
  @_$core.override
  _$jni.JObjType get superType => const _$jni.JObjectNullableType();

  @_$jni.internal
  @_$core.override
  _$jni.JObjType<PDDocumentInformation?> get nullableType =>
      const $PDDocumentInformation$NullableType();

  @_$jni.internal
  @_$core.override
  final superCount = 1;

  @_$core.override
  int get hashCode => ($PDDocumentInformation$Type).hashCode;

  @_$core.override
  bool operator ==(Object other) {
    return other.runtimeType == ($PDDocumentInformation$Type) &&
        other is $PDDocumentInformation$Type;
  }
}
