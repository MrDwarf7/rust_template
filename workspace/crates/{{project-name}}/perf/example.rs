use criterion::{Criterion, criterion_group, criterion_main};
use std::hint::black_box;

fn example_work(value: u64) -> u64 {
    (0..value).sum()
}

fn benchmark_example(c: &mut Criterion) {
    c.bench_function("example_work (benchmark-only example)", |b| {
        b.iter(|| example_work(black_box(1_000)))
    });
}

criterion_group!(benches, benchmark_example);
criterion_main!(benches);
