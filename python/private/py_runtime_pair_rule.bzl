# Copyright 2019 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Implementation of py_runtime_pair."""

load("//python:py_runtime_info.bzl", "PyRuntimeInfo")
load("//python/private:reexports.bzl", "BuiltinPyRuntimeInfo")

def _py_runtime_pair_impl(ctx):
    if ctx.attr.py2_runtime != None:
        py2_runtime = _get_py_runtime_info(ctx.attr.py2_runtime)
        if py2_runtime.python_version != "PY2":
            fail("The Python runtime in the 'py2_runtime' attribute did not have " +
                 "version 'PY2'")
    else:
        py2_runtime = None

    if ctx.attr.py3_runtime != None:
        py3_runtime = _get_py_runtime_info(ctx.attr.py3_runtime)
        if py3_runtime.python_version != "PY3":
            fail("The Python runtime in the 'py3_runtime' attribute did not have " +
                 "version 'PY3'")
    else:
        py3_runtime = None

    # TODO: Uncomment this after --incompatible_python_disable_py2 defaults to true
    # if _is_py2_disabled(ctx) and py2_runtime != None:
    #     fail("Using Python 2 is not supported and disabled; see " +
    #          "https://github.com/bazelbuild/bazel/issues/15684")

    return [platform_common.ToolchainInfo(
        py2_runtime = py2_runtime,
        py3_runtime = py3_runtime,
    )]

def _get_py_runtime_info(target):
    if PyRuntimeInfo in target:
        return target[PyRuntimeInfo]
    else:
        return target[BuiltinPyRuntimeInfo]

# buildifier: disable=unused-variable
def _is_py2_disabled(ctx):
    # Because this file isn't bundled with Bazel, so we have to conditionally
    # check for this flag.
    # TODO: Remove this once all supported Balze versions have this flag.
    if not hasattr(ctx.fragments.py, "disable_py"):
        return False
    return ctx.fragments.py.disable_py2

py_runtime_pair = rule(
    implementation = _py_runtime_pair_impl,
    attrs = {
        # The two runtimes are used by the py_binary at runtime, and so need to
        # be built for the target platform.
        "py2_runtime": attr.label(
            providers = [[PyRuntimeInfo], [BuiltinPyRuntimeInfo]],
            cfg = "target",
            doc = """\
The runtime to use for Python 2 targets. Must have `python_version` set to
`PY2`.
""",
        ),
        "py3_runtime": attr.label(
            providers = [[PyRuntimeInfo], [BuiltinPyRuntimeInfo]],
            cfg = "target",
            doc = """\
The runtime to use for Python 3 targets. Must have `python_version` set to
`PY3`.
""",
        ),
    },
    fragments = ["py"],
    doc = """\
A toolchain rule for Python.

This wraps up to two Python runtimes, one for Python 2 and one for Python 3.
The rule consuming this toolchain will choose which runtime is appropriate.
Either runtime may be omitted, in which case the resulting toolchain will be
unusable for building Python code using that version.

Usually the wrapped runtimes are declared using the `py_runtime` rule, but any
rule returning a `PyRuntimeInfo` provider may be used.

This rule returns a `platform_common.ToolchainInfo` provider with the following
schema:

```python
platform_common.ToolchainInfo(
    py2_runtime = <PyRuntimeInfo or None>,
    py3_runtime = <PyRuntimeInfo or None>,
)
```

Example usage:

```python
# In your BUILD file...

load("@rules_python//python:defs.bzl", "py_runtime_pair")

py_runtime(
    name = "my_py2_runtime",
    interpreter_path = "/system/python2",
    python_version = "PY2",
)

py_runtime(
    name = "my_py3_runtime",
    interpreter_path = "/system/python3",
    python_version = "PY3",
)

py_runtime_pair(
    name = "my_py_runtime_pair",
    py2_runtime = ":my_py2_runtime",
    py3_runtime = ":my_py3_runtime",
)

toolchain(
    name = "my_toolchain",
    target_compatible_with = <...>,
    toolchain = ":my_py_runtime_pair",
    toolchain_type = "@rules_python//python:toolchain_type",
)
```

```python
# In your WORKSPACE...

register_toolchains("//my_pkg:my_toolchain")
```
""",
)
