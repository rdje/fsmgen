//! Test-only JSON projection for the first Rust check smoke.
//!
//! This binary is deliberately not wired into the shipped Perl CLI. It lets the
//! Perl parity smoke execute the Rust crate and compare a normalized public
//! check-result projection against the Perl oracle.

#![forbid(unsafe_code)]

use std::env;
use std::fmt::Write as _;
use std::fs;
use std::process;

use fsmgen_portable_api::{execute, JsonValue, Operation, Request, SourceEnvelope, SourceKind};

fn main() {
    match run(env::args().skip(1)) {
        Ok(json) => println!("{json}"),
        Err(message) => {
            eprintln!("{message}");
            process::exit(2);
        }
    }
}

fn run(mut args: impl Iterator<Item = String>) -> Result<String, String> {
    let source_path = args
        .next()
        .ok_or_else(|| "usage: fsmgen-portable-api-check-smoke <source.fsm>".to_string())?;
    if args.next().is_some() {
        return Err("usage: fsmgen-portable-api-check-smoke <source.fsm>".to_string());
    }

    let source_text = fs::read_to_string(&source_path)
        .map_err(|error| format!("failed to read {source_path}: {error}"))?;
    let request = Request::new(
        Operation::Check,
        SourceEnvelope::new(source_path, Some(SourceKind::Fsm), source_text),
    );
    let result = execute(request);

    if !result.success {
        return Err("Rust check smoke returned an unsupported result".to_string());
    }

    match result.reports.get("check_json") {
        Some(report) => Ok(json_to_string(report)),
        None => Err("Rust check smoke did not emit a check_json report".to_string()),
    }
}

fn json_to_string(value: &JsonValue) -> String {
    let mut output = String::new();
    write_json_value(&mut output, value);
    output
}

fn write_json_value(output: &mut String, value: &JsonValue) {
    match value {
        JsonValue::Null => output.push_str("null"),
        JsonValue::Bool(value) => output.push_str(if *value { "true" } else { "false" }),
        JsonValue::Number(value) => {
            write!(output, "{value}").expect("writing JSON number to String cannot fail");
        }
        JsonValue::String(value) => write_json_string(output, value),
        JsonValue::Array(values) => {
            output.push('[');
            for (index, item) in values.iter().enumerate() {
                if index > 0 {
                    output.push(',');
                }
                write_json_value(output, item);
            }
            output.push(']');
        }
        JsonValue::Object(entries) => {
            output.push('{');
            for (index, (key, item)) in entries.iter().enumerate() {
                if index > 0 {
                    output.push(',');
                }
                write_json_string(output, key);
                output.push(':');
                write_json_value(output, item);
            }
            output.push('}');
        }
    }
}

fn write_json_string(output: &mut String, value: &str) {
    output.push('"');
    for character in value.chars() {
        match character {
            '"' => output.push_str("\\\""),
            '\\' => output.push_str("\\\\"),
            '\u{08}' => output.push_str("\\b"),
            '\u{0c}' => output.push_str("\\f"),
            '\n' => output.push_str("\\n"),
            '\r' => output.push_str("\\r"),
            '\t' => output.push_str("\\t"),
            character if character <= '\u{1f}' => {
                write!(output, "\\u{:04x}", character as u32)
                    .expect("writing JSON escape to String cannot fail");
            }
            character => output.push(character),
        }
    }
    output.push('"');
}
