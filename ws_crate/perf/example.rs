use criterion::{Criterion, criterion_group, criterion_main};
use std::hint::black_box;

use {{ crate_name | replace: "-", "_" }}::{
    {{ crate_namespace }}Error, {{ crate_namespace }}Result,
};

fn example_result() -> {{ crate_namespace }}Result<()> {
    Err({{ crate_namespace }}Error::Generic("benchmark example".to_owned()))
}

fn benchmark_example(c: &mut Criterion) {
    c.bench_function("example_result (benchmark-only example)", |b| {
        b.iter(|| black_box(example_result()))
    });
}

criterion_group!(benches, benchmark_example);
criterion_main!(benches);
