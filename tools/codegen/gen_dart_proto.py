#!/usr/bin/env python3
"""Generate the Dart protobuf messages for packages/atv_remote from the
reference schema shipped with androidtvremote2.

The schema (polo.proto + remotemessage.proto) is read from the compiled
descriptors of the reference Python library, so the Dart side always matches
the protocol the reference client speaks. The emitted code depends only on
lib/src/proto/wire.dart (a tiny protobuf wire codec) - no protoc needed.

Usage:  python tools/codegen/gen_dart_proto.py
"""

from __future__ import annotations

import pathlib
import re

from androidtvremote2 import polo_pb2, remotemessage_pb2
from google.protobuf import descriptor_pb2
from google.protobuf.descriptor_pb2 import FieldDescriptorProto as F

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "packages/atv_remote/lib/src/proto"

SCALARS = {
    F.TYPE_INT32: ("int", "Int32", "0"),
    F.TYPE_UINT32: ("int", "Uint32", "0"),
    F.TYPE_BOOL: ("bool", "Bool", "false"),
    F.TYPE_STRING: ("String", "String", "''"),
    F.TYPE_BYTES: ("List<int>", "Bytes", "const <int>[]"),
}


def camel(name: str) -> str:
    parts = name.split("_")
    return parts[0] + "".join(p[:1].upper() + p[1:] for p in parts[1:])


def dart_type_name(type_name: str, prefix: str) -> str:
    # ".polo.wire.protobuf.Options.Encoding" -> "Options_Encoding"
    name = type_name.lstrip(".")
    if name.startswith(prefix + "."):
        name = name[len(prefix) + 1 :]
    return name.replace(".", "_")


class Gen:
    def __init__(self, fd: descriptor_pb2.FileDescriptorProto) -> None:
        self.fd = fd
        self.proto3 = fd.syntax == "proto3"
        self.out: list[str] = []
        self.enums: set[str] = set()
        self._collect_enums()

    def _collect_enums(self) -> None:
        for e in self.fd.enum_type:
            self.enums.add(e.name)

        def walk(msg, path):
            for e in msg.enum_type:
                self.enums.add("_".join(path + [msg.name, e.name]))
            for n in msg.nested_type:
                walk(n, path + [msg.name])

        for m in self.fd.message_type:
            walk(m, [])

    def emit(self, line: str = "") -> None:
        self.out.append(line)

    def enum(self, e, name: str) -> None:
        self.emit(f"/// Protobuf enum `{e.name}`. Unknown values are preserved.")
        self.emit(f"class {name} {{")
        self.emit(f"  const {name}._(this.value, this.name);")
        self.emit("  final int value;")
        self.emit("  final String name;")
        self.emit()
        for v in e.value:
            self.emit(f"  static const {v.name} = {name}._({v.number}, '{v.name}');")
        self.emit()
        self.emit(f"  static const List<{name}> values = [")
        for v in e.value:
            self.emit(f"    {v.name},")
        self.emit("  ];")
        self.emit()
        self.emit(f"  static final Map<int, {name}> _byValue = {{for (final v in values) v.value: v}};")
        self.emit(f"  static final Map<String, {name}> _byName = {{for (final v in values) v.name: v}};")
        self.emit()
        self.emit("  /// Returns the known constant for [value], or a new instance carrying it.")
        self.emit(f"  static {name} valueOf(int value) => _byValue[value] ?? {name}._(value, 'UNKNOWN($value)');")
        self.emit()
        self.emit("  /// Returns the constant named [name], or null.")
        self.emit(f"  static {name}? byName(String name) => _byName[name];")
        self.emit()
        self.emit("  @override")
        self.emit(f"  bool operator ==(Object other) => other is {name} && other.value == value;")
        self.emit()
        self.emit("  @override")
        self.emit("  int get hashCode => value.hashCode;")
        self.emit()
        self.emit("  @override")
        self.emit("  String toString() => name;")
        self.emit("}")
        self.emit()

    def message(self, m, path: list[str]) -> None:
        name = "_".join(path + [m.name])
        for e in m.enum_type:
            self.enum(e, f"{name}_{e.name}")
        for n in m.nested_type:
            self.message(n, path + [m.name])

        fields = sorted(m.field, key=lambda f: f.number)
        self.emit(f"/// Protobuf message `{m.name}`.")
        self.emit(f"class {name} {{")
        if fields:
            args = []
            inits = []
            for f in fields:
                n = camel(f.name)
                if f.label == F.LABEL_REPEATED:
                    inner = self.tname(f) if f.type in (F.TYPE_MESSAGE, F.TYPE_ENUM) else SCALARS[f.type][0]
                    args.append(f"List<{inner}>? {n}")
                    inits.append(f"{n} = {n} ?? []")
                else:
                    args.append(f"this.{n}")
            init = f" : {', '.join(inits)}" if inits else ""
            self.emit(f"  {name}({{{', '.join(args)}}}){init};")
        else:
            self.emit(f"  {name}();")
        self.emit()
        for f in fields:
            self.emit(f"  {self.field_decl(f)}")
        self.emit()

        # encode
        self.emit("  /// Serializes this message (fields in tag order, like the reference).")
        self.emit("  List<int> writeToBuffer() {")
        self.emit("    final w = ProtoWriter();")
        self.emit("    writeTo(w);")
        self.emit("    return w.takeBytes();")
        self.emit("  }")
        self.emit()
        self.emit("  void writeTo(ProtoWriter w) {")
        for f in fields:
            self.emit_write(f)
        self.emit("  }")
        self.emit()

        # decode
        self.emit(f"  static {name} fromBuffer(List<int> bytes) => readFrom(ProtoReader(bytes));")
        self.emit()
        self.emit(f"  static {name} readFrom(ProtoReader r) {{")
        self.emit(f"    final m = {name}();")
        self.emit("    while (!r.isAtEnd) {")
        self.emit("      final tag = r.readTag();")
        self.emit("      switch (tag.field) {")
        for f in fields:
            self.emit_read(f)
        self.emit("        default:")
        self.emit("          r.skip(tag.wireType);")
        self.emit("      }")
        self.emit("    }")
        self.emit("    return m;")
        self.emit("  }")
        self.emit()
        self.emit("  @override")
        parts = " ".join(f"{camel(f.name)}: ${{{camel(f.name)}}}" for f in fields)
        self.emit(f"  String toString() => '{name}({parts})';")
        self.emit("}")
        self.emit()

    def tname(self, f) -> str:
        return dart_type_name(f.type_name, self.fd.package)

    def field_decl(self, f) -> str:
        n = camel(f.name)
        if f.label == F.LABEL_REPEATED:
            inner = self.tname(f) if f.type in (F.TYPE_MESSAGE, F.TYPE_ENUM) else SCALARS[f.type][0]
            return f"List<{inner}> {n};"
        if f.type in (F.TYPE_MESSAGE, F.TYPE_ENUM):
            return f"{self.tname(f)}? {n};"
        return f"{SCALARS[f.type][0]}? {n};"

    def emit_write(self, f) -> None:
        n = camel(f.name)
        num = f.number
        if f.label == F.LABEL_REPEATED:
            if f.type == F.TYPE_MESSAGE:
                self.emit(f"    for (final v in {n}) {{")
                self.emit(f"      w.writeMessage({num}, v.writeTo);")
                self.emit("    }")
            else:
                raise NotImplementedError(f"repeated {f.type}")
            return
        if f.type == F.TYPE_MESSAGE:
            self.emit(f"    final {n}V = {n};")
            self.emit(f"    if ({n}V != null) w.writeMessage({num}, {n}V.writeTo);")
            return
        if f.type == F.TYPE_ENUM:
            cond = f"{n} != null" + (f" && {n}!.value != 0" if self.proto3 else "")
            self.emit(f"    if ({cond}) w.writeEnum({num}, {n}!.value);")
            return
        _, kind, default = SCALARS[f.type]
        if self.proto3:
            if f.type == F.TYPE_BYTES or f.type == F.TYPE_STRING:
                cond = f"{n} != null && {n}!.isNotEmpty"
            elif f.type == F.TYPE_BOOL:
                cond = f"{n} == true"
            else:
                cond = f"{n} != null && {n} != 0"
        else:
            cond = f"{n} != null"
        self.emit(f"    if ({cond}) w.write{kind}({num}, {n}!);")

    def emit_read(self, f) -> None:
        n = camel(f.name)
        self.emit(f"        case {f.number}:")
        if f.label == F.LABEL_REPEATED:
            self.emit(f"          m.{n}.add({self.tname(f)}.readFrom(r.readSubReader()));")
        elif f.type == F.TYPE_MESSAGE:
            self.emit(f"          m.{n} = {self.tname(f)}.readFrom(r.readSubReader());")
        elif f.type == F.TYPE_ENUM:
            self.emit(f"          m.{n} = {self.tname(f)}.valueOf(r.readInt32());")
        else:
            kind = SCALARS[f.type][1]
            self.emit(f"          m.{n} = r.read{kind}();")

    def generate(self, header: str) -> str:
        self.emit(header)
        for e in self.fd.enum_type:
            self.enum(e, e.name)
        for m in self.fd.message_type:
            self.message(m, [])
        text = "\n".join(self.out).rstrip() + "\n"
        return re.sub(r"\n{3,}", "\n\n", text)


HEADER = """// GENERATED by tools/codegen/gen_dart_proto.py from {src}. Do not edit.
// ignore_for_file: constant_identifier_names, camel_case_types, curly_braces_in_flow_control_structures, unnecessary_brace_in_string_interps, lines_longer_than_80_chars

import 'wire.dart';
"""


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for module, out_name in ((polo_pb2, "polo.pb.dart"), (remotemessage_pb2, "remotemessage.pb.dart")):
        fd = descriptor_pb2.FileDescriptorProto()
        module.DESCRIPTOR.CopyToProto(fd)
        code = Gen(fd).generate(HEADER.format(src=fd.name))
        (OUT / out_name).write_text(code)
        print(f"wrote {OUT / out_name} ({len(code.splitlines())} lines)")


if __name__ == "__main__":
    main()
