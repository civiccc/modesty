module Modesty
  class Experiment
    class Significance

      #this is the table for up to 4 degrees of freedom.  If we are going to use
      #more than this we should actually have a flat file with the table that we
      #can parse.
      CHI_SQUARE_TABLE = {
        1 => {
          2.7055 => 0.10,
          3.8415 => 0.05,
          5.0239 => 0.025,
          6.6349 => 0.01, 
          7.8794 => 0.005
        },
        2 => {
          4.6052 => 0.10,
          5.9915 => 0.05,
          7.3778 => 0.025,
          9.2104 => 0.01,
          10.5965 => 0.005
        },
        3 => {
          6.2514 => 0.10,
          7.8147 => 0.05,
          9.3484 => 0.025,
          11.349 => 0.01,
          12.8381 => 0.005
        },
        4 => {
          7.7794 => 0.10,
          9.4877 => 0.05,
          11.1433 => 0.025,
          13.2767 => 0.01,
          14.860 => 0.005
        },
        5 => {
          9.236  => 0.10,
          11.070 => 0.05,
          12.833 => 0.025,
          15.086 => 0.01,
          16.750 => 0.005
        },
        6 => {
          10.645 => 0.10,
          12.592 => 0.05,
          14.449 => 0.025,
          16.812 => 0.01,
          18.548 => 0.005
        },
        7 => {
          12.017 => 0.10,
          14.067 => 0.05,
          16.013 => 0.025,
          18.475 => 0.01,
          20.278 => 0.005
        },
        8 => {
          13.362 => 0.10,
          15.507 => 0.05,
          17.535 => 0.025,
          20.090 => 0.01,
          21.955 => 0.005
        }
      }
         
      def self.significance(*args)
        df = (args.size - 1) * (args[0].size - 1)
        raise "Currently unimplemented:  More than 8 degrees of freedom" if df > 8
        chi_square = self.chi_square(args)
        current = nil
        CHI_SQUARE_TABLE[df].keys.sort.each do |key|
          if chi_square > key
            current = CHI_SQUARE_TABLE[df][key]
          end
        end
        current
      end

      # return an hash with all the values from the distributions in it, not
      # necessarily sorted. Basically, pool all the histograms.
      def self.pool_distributions(distributions)
        pooled_distribution = Hash.new(0)
        distributions.each do |name, frequency_map|
          frequency_map.each do |key, value|
            pooled_distribution[key] += value
          end
        end
        pooled_distribution
      end

      # Take a histogram and turn it into an array
      def self.squash_distribution(distribution)
        a_flattened_histogram = []
        distribution.each do |key, value|
          (0..value).each do
            a_flattened_histogram << key
          end
        end
        a_flattened_histogram
      end

      # pick two unique samples from 'array' of size num_elements
      def self.bi_sample_array(array, num_elements)
        raise "We don't have that many elements" unless num_elements*2 <= array.size
        values = array.shuffle
        [values[0...num_elements], values[num_elements...2*num_elements]]
      end

      def self.add_sums(rows)
        size = nil
        rows.each do |row|
          size = row.size unless size
          raise "Unequal sized rows!" if size != row.size
          row.push row.sum
        end
        new_row = [0] * (size + 1)
        rows.each do |row|
          new_row = new_row.zip(row).map(&:sum)
        end
        rows.push new_row
      end

      def self.chi_square(rows)
        rows = self.add_sums(rows)

        chi_square = 0
        num_rows = rows.size
        len = rows[0].size
        (0...num_rows).each do |i|
          (0...len).each do |j|
            error = rows[i][len - 1].to_f * rows[num_rows - 1][j].to_f /
                    rows[num_rows - 1][len - 1].to_f
            chi_square += ((error - rows[i][j])**2) / error
          end
        end
        chi_square
      end


      def self.size_total_mean_and_stdev(distribution)
        total = 0
        size = 0
        distribution.each do |pair|
          value = pair[0].to_i
          freq = pair[1].to_i
          total += value * freq
          size += freq
        end
        mean = total.to_f / size
        stderr = 0
        distribution.each do |pair|
          value = pair[0].to_i
          freq = pair[1].to_i
          stderr += freq * ((value - mean)**2)
        end
        std_dev = (stderr.to_f / size) ** (0.5)
        [size, total, mean, std_dev]
      end


      #assume infinite df.  Numbers here are huge
      SIGNIFICANCE_VALUES = {1.282 => 0.10, 1.645 => 0.05, 1.960 => 0.025,
                             2.326 => 0.01, 2.576 => 0.005}

      # Let's also have a table of signifigant values based on degrees of freedom
      # and see if we can look up data in it
      #
      LOOKUP_SIGNIFICANCE_TABLE = {
        0 => 0.25,
        1 => 0.20,
        2 => 0.15,
        3 => 0.10,
        4 => 0.05,
        5 => 0.025,
        6 => 0.01,
        7 => 0.005,
      }

      # Taken from Wikipedia's page on Student's T distribution
      SIGNIFICANCE_VALUES_FOR_V = {
      # V           75%     80%     85%     90%     95%     97.5%   99%     99.5%   99.75%  99.9%   99.95%
        1   => [ 	1.000, 	1.376, 	1.963, 	3.078, 	6.314, 	12.71, 	31.82, 	63.66, 	127.3, 	318.3, 	636.6 ],
        2   => [ 	0.816, 	1.061, 	1.386, 	1.886, 	2.920, 	4.303, 	6.965, 	9.925, 	14.09, 	22.33, 	31.60 ],
        3   => [ 	0.765, 	0.978, 	1.250, 	1.638, 	2.353, 	3.182, 	4.541, 	5.841, 	7.453, 	10.21, 	12.92 ],
        4   => [ 	0.741, 	0.941, 	1.190, 	1.533, 	2.132, 	2.776, 	3.747, 	4.604, 	5.598, 	7.173, 	8.610 ],
        5   => [ 	0.727, 	0.920, 	1.156, 	1.476, 	2.015, 	2.571, 	3.365, 	4.032, 	4.773, 	5.893, 	6.869 ],
        6   => [ 	0.718, 	0.906, 	1.134, 	1.440, 	1.943, 	2.447, 	3.143, 	3.707, 	4.317, 	5.208, 	5.959 ],
        7   => [ 	0.711, 	0.896, 	1.119, 	1.415, 	1.895, 	2.365, 	2.998, 	3.499, 	4.029, 	4.785, 	5.408 ],
        8   => [ 	0.706, 	0.889, 	1.108, 	1.397, 	1.860, 	2.306, 	2.896, 	3.355, 	3.833, 	4.501, 	5.041 ],
        9   => [ 	0.703, 	0.883, 	1.100, 	1.383, 	1.833, 	2.262, 	2.821, 	3.250, 	3.690, 	4.297, 	4.781 ],
        10  => [ 	0.700, 	0.879, 	1.093, 	1.372, 	1.812, 	2.228, 	2.764, 	3.169, 	3.581, 	4.144, 	4.587 ],
        11  => [ 	0.697, 	0.876, 	1.088, 	1.363, 	1.796, 	2.201, 	2.718, 	3.106, 	3.497, 	4.025, 	4.437 ],
        12  => [ 	0.695, 	0.873, 	1.083, 	1.356, 	1.782, 	2.179, 	2.681, 	3.055, 	3.428, 	3.930, 	4.318 ],
        13  => [ 	0.694, 	0.870, 	1.079, 	1.350, 	1.771, 	2.160, 	2.650, 	3.012, 	3.372, 	3.852, 	4.221 ],
        14  => [ 	0.692, 	0.868, 	1.076, 	1.345, 	1.761, 	2.145, 	2.624, 	2.977, 	3.326, 	3.787, 	4.140 ],
        15  => [ 	0.691, 	0.866, 	1.074, 	1.341, 	1.753, 	2.131, 	2.602, 	2.947, 	3.286, 	3.733, 	4.073 ],
        16  => [ 	0.690, 	0.865, 	1.071, 	1.337, 	1.746, 	2.120, 	2.583, 	2.921, 	3.252, 	3.686, 	4.015 ],
        17  => [ 	0.689, 	0.863, 	1.069, 	1.333, 	1.740, 	2.110, 	2.567, 	2.898, 	3.222, 	3.646, 	3.965 ],
        18  => [ 	0.688, 	0.862, 	1.067, 	1.330, 	1.734, 	2.101, 	2.552, 	2.878, 	3.197, 	3.610, 	3.922 ],
        19  => [ 	0.688, 	0.861, 	1.066, 	1.328, 	1.729, 	2.093, 	2.539, 	2.861, 	3.174, 	3.579, 	3.883 ],
        20  => [ 	0.687, 	0.860, 	1.064, 	1.325, 	1.725, 	2.086, 	2.528, 	2.845, 	3.153, 	3.552, 	3.850 ],
        21  => [ 	0.686, 	0.859, 	1.063, 	1.323, 	1.721, 	2.080, 	2.518, 	2.831, 	3.135, 	3.527, 	3.819 ],
        22  => [ 	0.686, 	0.858, 	1.061, 	1.321, 	1.717, 	2.074, 	2.508, 	2.819, 	3.119, 	3.505, 	3.792 ],
        23  => [ 	0.685, 	0.858, 	1.060, 	1.319, 	1.714, 	2.069, 	2.500, 	2.807, 	3.104, 	3.485, 	3.767 ],
        24  => [ 	0.685, 	0.857, 	1.059, 	1.318, 	1.711, 	2.064, 	2.492, 	2.797, 	3.091, 	3.467, 	3.745 ],
        25  => [ 	0.684, 	0.856, 	1.058, 	1.316, 	1.708, 	2.060, 	2.485, 	2.787, 	3.078, 	3.450, 	3.725 ],
        26  => [ 	0.684, 	0.856, 	1.058, 	1.315, 	1.706, 	2.056, 	2.479, 	2.779, 	3.067, 	3.435, 	3.707 ],
        27  => [ 	0.684, 	0.855, 	1.057, 	1.314, 	1.703, 	2.052, 	2.473, 	2.771, 	3.057, 	3.421, 	3.690 ],
        28  => [ 	0.683, 	0.855, 	1.056, 	1.313, 	1.701, 	2.048, 	2.467, 	2.763, 	3.047, 	3.408, 	3.674 ],
        29  => [ 	0.683, 	0.854, 	1.055, 	1.311, 	1.699, 	2.045, 	2.462, 	2.756, 	3.038, 	3.396, 	3.659 ],
        30  => [ 	0.683, 	0.854, 	1.055, 	1.310, 	1.697, 	2.042, 	2.457, 	2.750, 	3.030, 	3.385, 	3.646 ],
        40  => [ 	0.681, 	0.851, 	1.050, 	1.303, 	1.684, 	2.021, 	2.423, 	2.704, 	2.971, 	3.307, 	3.551 ],
        50  => [ 	0.679, 	0.849, 	1.047, 	1.299, 	1.676, 	2.009, 	2.403, 	2.678, 	2.937, 	3.261, 	3.496 ],
        60  => [ 	0.679, 	0.848, 	1.045, 	1.296, 	1.671, 	2.000, 	2.390, 	2.660, 	2.915, 	3.232, 	3.460 ],
        80  => [ 	0.678, 	0.846, 	1.043, 	1.292, 	1.664, 	1.990, 	2.374, 	2.639, 	2.887, 	3.195, 	3.416 ],
        100 => [ 	0.677, 	0.845, 	1.042, 	1.290, 	1.660, 	1.984, 	2.364, 	2.626, 	2.871, 	3.174, 	3.390 ],
        120 => [ 	0.677, 	0.845, 	1.041, 	1.289, 	1.658, 	1.980, 	2.358, 	2.617, 	2.860, 	3.160, 	3.373 ],
        0   => [    0.674, 	0.842, 	1.036, 	1.282, 	1.645, 	1.960, 	2.326, 	2.576, 	2.807, 	3.090, 	3.291 ],
      }

      # Calculate the p_value for a given t,v from the student's t distribution
      def calculate_p_value(t_val, v_val=0)
        v_arr = SIGNIFICANCE_VALUES_FOR_V[v]

        return nil if !v_arr

        v_arr = v_arr.sort()
        lookup_val = nil
        # find the largest value that t_val is greater than
        v_arr.each do | v_val |
          lookup_val = v_val if t_val > v_val
        end

        # return the p_value that corresponds to it
        index_into_v_arr = v_arr.index(lookup_val)
        return LOOKUP_SIGNIFICANCE_TABLE[index_into_v_arr]
      end

      def self.calculate_histogram_stats(distributions)
        #distributions should be hash of {name => histogram }
        stats = distributions.inject({}) do |hash, pair|
          size, tot, mean, sdev = self.size_total_mean_and_stdev(pair[1])
          hash[pair[0]] = {:size => size, :total => tot,
                           :mean => mean, :sdev => sdev}
          hash
        end
        return stats
      end


      # [okay] my initial comments on the following function:
      # assumptions:
      #   * Does a signifigance check against V = infinity
      #   * assumes stddev for both distributions are equal.
      def self.dist_significance(distributions)
        #distributions should be hash of {name => histogram }
        stats = self.calculate_histogram_stats(distributions)
        if distributions.keys.size != 2
          #for now can only test for significance in pairwise.  To do more than
          #2, need to implement ANOVA
          return stats
        end

        # Run a student's T test on the distributions
        #
        # t = x1[:mean] - x2[:mean]
        #     ---------------------
        #     pooled_sdev * sqrt(1/n1 + 1/n2)
        #
        # where n1 is the number of elements in x1, n2 the number of elems in x2,
        # and pooled_sdev is:
        #
        # pooled_sdev = sqrt (  (n1 - 1)(sdev1**2) + (n2 - 1)(sdev2**2)  )
        #                    (  ---------------------------------------  )
        #                    (                n1 + n2 - 2                )
        pooled_sdev = stats.values.map {|hash| (hash[:size] - 1) * (hash[:sdev] ** 2)}.sum
        pooled_sdev /= (stats.values.map {|hash| hash[:size]}.sum - 2)
        pooled_sdev = pooled_sdev ** 0.5
        t_val = (stats.values.first[:mean] - stats.values.last[:mean]) /
                (pooled_sdev *
                (stats.values.map {|hash| 1.0 / hash[:size]}.sum ** 0.5))
        t_val = t_val.abs
        current_sig = nil
        SIGNIFICANCE_VALUES.keys.sort.each do |key|
          if t_val > key
            current_sig = SIGNIFICANCE_VALUES[key]
          end
        end
        stats.merge(:significant => current_sig)
      end

      def self.welch_t_test(distributions)
        #distributions should be hash of {name => histogram }
        stats = self.calculate_histogram_stats(distributions)

        # Run a student's T test for assumed unequal size/unequal variance on the
        # populations
        #
        #
        # t =      x1[:mean] - x2[:mean]
        #     ------------------------------
        #     sqrt( sdev1**2     sdev2**2 )
        #         ( --------  +  -------- )
        #         (    n1          n2     )
        #
        # degrees of freedom (yuck, ugly ugly ugly)
        # The Welch-Satterthwaite approximation (also from wikipedia)
        # v = ( sdev1**2     sdev2**2)
        #     ( --------  +  --------) ** 2
        #     (    n1           n2   )
        #   --------------------------------
        #        sdev1**4          sdev2**4
        #     -------------- +  --------------
        #     n1**2 * (n1-1)    n2**2 * (n2-1)
        #
        #  it might be acceptable to assume infinite degrees of freedom. We shall see.


        denom = stats.values.map {|hash| (hash[:sdev]**2) / hash[:size] }.sum
        denom = denom ** 0.5 # Take the square root
        t_val = (stats.values.first[:mean] - stats.values.last[:mean]) / denom

        t_val = t_val.abs
        current_sig = nil

        current_sig = calculate_p_value(t_val, 0)
        stats.merge(:significant => current_sig)
      end

      # ideal: build all possible permutations of sample_size from distributions
      # and then compare them to each other.  since there is no 're-usage' of any
      # item, sample_size <= total size of population
      # num_permutations is the number of times to do this.
      def self.permutation_test(distributions, num_permutations=1000,
                                sample_size_percentage=0.2)
        stats = self.calculate_histogram_stats(distributions)
        # Data comes in histogram form? Hmmm. Need to massage it into an array
        # A histogram of all distributions
        pooled_dist = self.pool_distributions(distributions)
        # An array with all possible values
        pooled_flat = self.squash_distribution(pooled_dist)
        sample_size = pooled_flat.count * sample_size_percentage

        # Let's try with ruby's random number generator for a while.
        mean_differences = []
        (0..num_permutations).each do |i|
          samples = self.bi_sample_array(pooled_flat, sample_size)
          mean_differences << (samples[0].mean - samples[1].mean).abs
        end

        mean_differences = mean_differences.sort

        # Find the index of where the sample difference means falls
        dist_mean_diff = (stats.values.first[:mean] - stats.values.last[:mean]).abs

        # run through the mean differences in sorted order until we find a value
        # that is greater than dist_mean_diff or run off the array
        fit_index = 0
        while fit_index < mean_differences.count do
          break if dist_mean_diff < mean_differences[fit_index]
          fit_index += 1
        end

        # calculate where fit_index falls in the array - for it to be statistically
        # signifigant, it has to fall in the top 5 - 10% of mean differences,
        # i.e. greater than array.count * .90. I think.
        fp = fit_index.to_f / num_permutations.to_f

        # We want to return 1 - the possibility, I guess.
        1.0 - fp

      end
    end
  end
end
