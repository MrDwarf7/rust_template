/// Computes the Leveshtein distance between two input strings
///
/// # Arguments
/// * `a` - a string
/// * `b` - a string
///
/// # Returns
/// * the Levenshtein distance between `a` and `b`
///
/// # Examples
/// ```
/// use levenshtein_lite::levenshtein_distance;
/// assert!(levenshtein_distance("abc", "abx") == 1);
/// assert!(levenshtein_distance("abc", "axx") == 2);
/// ```
// Credit: github.com:danmunson/levenshtein_lite
pub fn levenshtein_distance_matrix(a: &str, b: &str) -> i32 {
    use std::cmp::min;
    let (rowstr, colstr) = (a, b);
    let mut prev = (0..rowstr.len() as i32 + 1).collect::<Vec<i32>>();
    let mut current = prev.clone();
    for (uci, cchar) in colstr.chars().enumerate() {
        current[0] = uci as i32 + 1;
        for (uri, rchar) in rowstr.chars().enumerate() {
            let ri = uri + 1;
            let r_insert_d = prev[ri] + 1;
            let r_del_d = current[ri - 1] + 1;
            let r_match_or_sub_d = if rchar == cchar { prev[ri - 1] } else { prev[ri - 1] + 1 };
            current[ri] = min(r_match_or_sub_d, min(r_insert_d, r_del_d));
        }
        // swap current and prev
        // (current, prev) = (prev, current);
        // Maybe quicker?
        std::mem::swap(&mut prev, &mut current);
    }
    // because of the swap,
    // prev is actually the last set of distances
    prev[prev.len() - 1]
}

// Credit: github.com:wooorm/levenshtein-rs
#[rustfmt::skip]
pub fn levenshtein_distance_array(a: &str, b: &str) -> usize {
    let mut result = 0;

    // Shortcut optimizations / degenerate cases.
    if a == b { return result; }

    let length_a = a.chars().count();
    let length_b = b.chars().count();

    if length_a == 0 { return length_b; }
    if length_b == 0 { return length_a; }

    /// Initialize the vector.
    // This is why it’s fast, normally a matrix is used,
    // here we use a single vector.
    let mut cache: Vec<usize> = (1..).take(length_a).collect();
    // Loop.
    for (index_b, code_b) in b.chars().enumerate() {
        result = index_b;
        let mut distance_a = index_b;
        for (index_a, code_a) in a.chars().enumerate() {
            let distance_b = if code_a == code_b { distance_a } else { distance_a + 1 };
            distance_a = cache[index_a];
            result = if distance_a > result {
                if distance_b > result { result + 1 } else { distance_b }
            } else 
                if distance_b > distance_a { distance_a + 1 } 
                else {
                    distance_b 
                };
            cache[index_a] = result;
        }
    }
    result
}

#[rustfmt::skip]
pub fn levenshtein_distance_gptlol(s1: &str, s2: &str) -> usize {
    use std::cmp::min;
    let len1 = s1.len();
    let len2 = s2.len();
    
    if len1 == 0 { return len2; }
    if len2 == 0 { return len1; }

    // Create a distance array for the current and previous row
    let mut previous = (0..=len2).collect::<Vec<usize>>();
    let mut current = vec![0; len2 + 1];

    #[rustfmt::skip]
    for i in 1..=len1 {
        current[0] = i;
        for j in 1..=len2 {
            // Calculate costs
            let cost = if s1.as_bytes()[i - 1] == s2.as_bytes()[j - 1] { 0 } else { 1 };
            current[j] = *[
                previous[j] + 1,      // Deletion
                current[j - 1] + 1,  // Insertion
                previous[j - 1] + cost, // Substitution
            ].iter().min().unwrap();
        }
        // Swap references instead of copying
        std::mem::swap(&mut previous, &mut current);
    }
    previous[len2]
}
