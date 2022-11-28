/*******************************************************************************
 * Copyright (C) 2016-2019 Dennis Cosgrove
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 ******************************************************************************/

package range.warmup;

import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.LinkedList;
import java.util.List;

import org.junit.runners.Parameterized.Parameters;

/**
 * @author Dennis Cosgrove (http://www.cse.wustl.edu/~cosgroved/)
 */
public class DoubleRangeWithoutStepTest extends AbstractRangeTest<Double> {
	private final double min;
	private final double maxExclusive;

	public DoubleRangeWithoutStepTest(List<Double> expected, double min, double maxExclusive) {
		super(expected);
		this.min = min;
		this.maxExclusive = maxExclusive;
	}

	@Override
	protected Iterable<Double> createIterable() {
		return Iterables.range(min, maxExclusive);
	}

	@Parameters(name = "expected: {0}; min: {1}; maxExclusive: {2}; step: {3}")
	public static Collection<Object[]> getConstructorArguments() {
		// note: must be careful not to rounding error
		List<Object[]> result = new LinkedList<>();
		result.add(new Object[] { Collections.emptyList(), 0, 0});
		result.add(new Object[] { Collections.emptyList(), 1, 0 });
		result.add(new Object[] { Collections.emptyList(), 425, 231 });
		result.add(new Object[] { Arrays.asList(0.0), 0, 1 });
		result.add(new Object[] { Arrays.asList(425.0), 425, 426 });
		result.add(new Object[] { Arrays.asList(0.0, 1.0, 2.0), 0, 3 });
		result.add(new Object[] { Arrays.asList(4.0, 5.0, 6.0, 7.0, 8.0), 4, 9 });
		return result;
	}

}
