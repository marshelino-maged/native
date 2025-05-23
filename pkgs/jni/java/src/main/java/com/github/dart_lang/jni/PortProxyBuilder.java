// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.github.dart_lang.jni;

import java.lang.reflect.*;
import java.util.*;

public class PortProxyBuilder implements InvocationHandler {
  private static final PortCleaner cleaner = new PortCleaner();
  private static final Method equals;
  private static final Method hashCode;
  private static final Method toString;

  static {
    Class<Object> object = Object.class;
    try {
      equals = object.getDeclaredMethod("equals", object);
      hashCode = object.getDeclaredMethod("hashCode");
      toString = object.getDeclaredMethod("toString");
    } catch (NoSuchMethodException e) {
      // Never happens.
      throw new Error();
    }
    System.loadLibrary("dartjni");
  }

  private static final class DartImplementation {
    final long port;
    final long pointer;

    DartImplementation(long port, long pointer) {
      this.port = port;
      this.pointer = pointer;
    }
  }

  private boolean built = false;
  private final long isolateId;
  private final boolean constructedOnMainThread;
  private final HashMap<String, DartImplementation> implementations = new HashMap<>();
  private final HashSet<String> asyncMethods = new HashSet<>();

  private static boolean isOnMainThread() {
    try {
      Class<?> looper = Class.forName("android.os.Looper");
      Method getMainLooper = looper.getMethod("getMainLooper");
      Method getThread = looper.getMethod("getThread");
      Thread mainThread = (Thread) getThread.invoke(getMainLooper.invoke(null));
      return mainThread == Thread.currentThread();
    } catch (Exception e) {
      // Not on Android, so there is no concept of a "main" thread.
      return false;
    }
  }

  public PortProxyBuilder(long isolateId) {
    this.isolateId = isolateId;
    this.constructedOnMainThread = isOnMainThread();
  }

  private static String getDescriptor(Method method) {
    StringBuilder descriptor = new StringBuilder();
    descriptor.append(method.getName()).append('(');
    Class<?>[] parameterTypes = method.getParameterTypes();
    for (Class<?> paramType : parameterTypes) {
      appendType(descriptor, paramType);
    }
    descriptor.append(')');
    appendType(descriptor, method.getReturnType());
    return descriptor.toString();
  }

  private static void appendType(StringBuilder descriptor, Class<?> type) {
    if (type == void.class) {
      descriptor.append('V');
    } else if (type == boolean.class) {
      descriptor.append('Z');
    } else if (type == byte.class) {
      descriptor.append('B');
    } else if (type == char.class) {
      descriptor.append('C');
    } else if (type == short.class) {
      descriptor.append('S');
    } else if (type == int.class) {
      descriptor.append('I');
    } else if (type == long.class) {
      descriptor.append('J');
    } else if (type == float.class) {
      descriptor.append('F');
    } else if (type == double.class) {
      descriptor.append('D');
    } else if (type.isArray()) {
      descriptor.append('[');
      appendType(descriptor, type.getComponentType());
    } else {
      descriptor.append('L').append(type.getName().replace('.', '/')).append(';');
    }
  }

  public void addImplementation(
      String binaryName, long port, long functionPointer, List<String> asyncMethods) {
    implementations.put(binaryName, new DartImplementation(port, functionPointer));
    this.asyncMethods.addAll(asyncMethods);
  }

  public Object build() throws ClassNotFoundException {
    if (implementations.isEmpty()) {
      throw new IllegalStateException("No interface implementation added");
    }
    if (built) {
      throw new IllegalStateException("This proxy has already been built");
    }
    built = true;
    ArrayList<Class<?>> classes = new ArrayList<>();
    for (String binaryName : implementations.keySet()) {
      classes.add(Class.forName(binaryName));
    }
    Object obj =
        Proxy.newProxyInstance(
            classes.get(0).getClassLoader(), classes.toArray(new Class<?>[0]), this);
    for (DartImplementation implementation : implementations.values()) {
      cleaner.register(obj, implementation.port);
    }
    return obj;
  }

  /// Returns an array with two objects:
  /// [0]: The address of the result pointer used for the clean-up.
  /// [1]: The result of the invocation.
  private static native Object[] _invoke(
      long port,
      long isolateId,
      long functionPtr,
      Object proxy,
      String methodDescriptor,
      Object[] args,
      boolean isBlocking,
      boolean mayEnterIsolate);

  private static native void _cleanUp(long resultPtr);

  @Override
  public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
    if (method.equals(equals)) {
      return proxy == args[0];
    }
    if (method.equals(hashCode)) {
      return System.identityHashCode(proxy);
    }
    if (method.equals(toString)) {
      return proxy.getClass().getName() + '@' + Integer.toHexString(System.identityHashCode(proxy));
    }
    DartImplementation implementation = implementations.get(method.getDeclaringClass().getName());
    String descriptor = getDescriptor(method);
    boolean isBlocking = !asyncMethods.contains(descriptor);
    boolean mayEnterIsolate = isOnMainThread() && constructedOnMainThread;
    Object[] result =
        _invoke(
            implementation.port,
            isolateId,
            implementation.pointer,
            proxy,
            descriptor,
            args,
            isBlocking,
            mayEnterIsolate);
    if (!isBlocking) {
      return null;
    }
    _cleanUp((Long) result[0]);
    if (result[1] instanceof DartException) {
      Throwable cause = ((DartException) result[1]).cause;
      if (cause != null) {
        throw cause;
      } else {
        throw (DartException) result[1];
      }
    }
    return result[1];
  }

  private static final class DartException extends Exception {
    Throwable cause;

    private DartException(String message, Throwable cause) {
      super(message);
      this.cause = cause;
    }
  }
}
