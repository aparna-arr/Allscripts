#!/usr/bin/env perl
use warnings;
use strict;
use threads;
use Thread::Queue;

### Global Variables ###
my $MUTATION_RATE   = 0.1;
my $MAX_MUTATION    = 0.2;
my $CROSSOVER_RATE  = 0.05;
my $PARENT_PERCENT  = 0.2;
my $ORDER           = 3;
my $NUM_EMISSIONS   = 6;
my $THRESHOLD       = 0.9;
my $THREADS         = 0;
my $EVAL_SCRIPT     = "/data/aparna/scripts/DRIPc_0.1_funcGA_eval.pl";
my $POP_SIZE        = 0;
my $OUT_DIR         = "";
###

# Default stochhmm command #
# stochhmm -model $model -seq $fasta -posterior -threshold 0.9 -gff > $outdir/$outfile

main();

sub main {

  my $usage = "
GA Stochhmm

usage : $0 -fasta <fasta sequence file> -model <initial hmm> -temp <template HMM without emissions> -pop <population size> -gens <number of generations> -threads <number of threads> -out <output dir>
";

  my ($fasta, $model, $template, $pop, $gens, $threads, $outdir) = @ARGV;
  #die $usage unless @ARGV;

  #validate_input();
  print "\nGot input\n";
  $THREADS = $threads;  
  $POP_SIZE = $pop;     
  $OUT_DIR = $outdir;
#  print "Threads is $THREADS, pop size is $POP_SIZE\n";
#  print "Call to generate_population\n";
  my @population = @{generate_population($model, $pop, $template, $outdir, $fasta)};
  # generates, mutates, evaluates
  print "Initial population generated\n";
  for (my $i = 0; $i < $gens; $i++) {
    my $max = 0;
    @population = sort{$b->{score}<=>$a->{score}} @population; #FIXME check this line
    @population = @{purge(\@population, $pop)};
    @population = @{mate(\@population)};
    my $pop_ref;
    ($max, $pop_ref) = evaluate(\@population, $template, $outdir, $fasta);
    @population = @{$pop_ref};
    print "Round $i result: \tMAX: $max\n\n";
  }
}

sub generate_population {
  my $input_model = $_[0];
  my $popsize = $_[1];
  my $template = $_[2];
  my $dir = $_[3];
  my $seq = $_[4];
  my @pop;
  my $max;
  my $ref;
#  print "In generate_population(). Threads is $THREADS, pop size is $POP_SIZE\n";
#  print "Call to read_HMM\n";
#  my ($emm) = read_HMM($input_model); # returns a reference to a array  
  my @emm = @{read_HMM($input_model)}; # returns a reference to a array  
  print "Done reading HMM\n";
  for (my $i = 0; $i < $popsize; $i++) {
    my @tempemm; # this is needed or else reference/pointer errors!
    for (my $n = 0; $n < @emm; $n++) {
      for (my $m = 0; $m < @{$emm[$n]}; $m++) {
        for (my $o = 0; $o < @{$emm[$n][$m]}; $o++) {
          $tempemm[$n][$m][$o] = $emm[$n][$m][$o];
        }
      }
    }
   # my @tempemm = @emm;
    push(@pop, {emm => \@tempemm, score => 0, model => "$i.hmm"});
  }

  @pop = @{mutate(\@pop)};
  
#  print "debug: generate_population(): printing emissions\n";
  # all emissions are the same
#  for (my $d = 0; $d < @pop; $d++) {
#    open (DEBUG, ">", "DEBUG_$d.txt");
#    print DEBUG "\td is $d\n";
#    for (my $e = 0; $e < @{$pop[$d]{emm}}; $e++) {
#      for (my $b = 0; $b < @{$pop[$d]{emm}[$e]}; $b++) {
#       print DEBUG "\t";
#        for (my $u = 0; $u < @{$pop[$d]{emm}[$e][$b]}; $u++) {
#          print DEBUG "$pop[$d]{emm}[$e][$b][$u] ";
#        }
#        print DEBUG "\n";
#      }
#    }
#    close DEBUG;
#  }

  ($max, $ref) = evaluate(\@pop, $template, $dir, $seq);
  
  @pop = @{$ref};
  print "Round 0 result: \tMAX: $max\n";
  print "Done initialization, now performing Genetic Algorithm\n";
  return(\@pop);
}

sub read_HMM {
  my $hmm = $_[0];

  open (HMM, "<", $hmm) or die "Could not open $hmm\n";

  my $next_emm = 0;
  my @states;
#  my $states_num = 0;
  my $states_num = -1;

  while(<HMM>) {
    my $line = $_;
    chomp $line;
    
#    if ($line =~ /^@/) {
#      $next_emm = 1;
#      $states_num++;
#    }
#    elsif ($line =~ /\#\#\#\#\#\#/) {
#      $next_emm = 0;
#    }

    if ($next_emm && $line !~ /\#\#\#\#\#\#/) {
      my @row = split(/\s+/, $line) ; # FIXME check following data structure, correct!
#      push (@{$states[$states_num]}, @row);
      push (@{$states[$states_num]}, \@row);
    }

    if ($line =~ /^@/) {
      $next_emm = 1;
      $states_num++;
    }
    elsif ($line =~ /\#\#\#\#\#\#/) {
      $next_emm = 0;
    }
    
  }
#  print "debug: read_HMM():\n";
#  print "\tstates_num: $states_num\n";
#  print "\tstates arr: " . @states . "\n";
#  for (my $d = 0; $d < @states; $d++) {
#    print "\t states[d]: $states[$d]\n";
#    for (my $e = 0; $e < 10; $e++) {
#      print "\tstates[d][e]: $states[$d][$e]\n";
#      for (my $b = 0; $b < @{$states[$d][$e]}; $b++) {
#        print "\t\t states[d][e][b]: $states[$d][$e][$b]\n";
#      }
#    }
#  }

  return (\@states);
}

sub mutate {
  my @pop = @{$_[0]};

#  print "debug0: mutate(): pop{score}:\n";

#    for (my $j = 0; $j < @pop; $j++) {
#      print "debug0: mutate(): pop $j val : $pop[$j]{emm}\n"; # they all refer to the same hash! pointer error!  
#      print "\tdebug0: mutate(): pop $j val : $pop[$j]{emm}[0]\n"; # they all refer to the same hash! pointer error!  
#      print "\t\tdebug0: mutate(): pop $j val : $pop[$j]{emm}[0][0]\n"; # they all refer to the same hash! pointer error!  
#      print "\tpop[$j]{score}: $pop[$j]{score}\n";
#    }  
  for (my $i = 0; $i < @pop ; $i++) {
    for (my $state = 0; $state < @{$pop[$i]{emm}}; $state++) {
# state-specific mutation conditionals here
#      for (my $row = 0; $row < $NUM_EMISSIONS**($ORDER-1); $row++) {
      for (my $row = 0; $row < $NUM_EMISSIONS**($ORDER); $row++) {
        for (my $col = 0; $col < $NUM_EMISSIONS; $col++) {
          if (rand(1) < $MUTATION_RATE) {
            my $diff = rand($MAX_MUTATION);
            if (rand(1) < 0.5) {
              $pop[$i]{emm}[$state][$row][$col]+=$diff;
            }
            else {
              $pop[$i]{emm}[$state][$row][$col]-=$diff;
              if ($pop[$i]{emm}[$state][$row][$col] < 1) {
                $pop[$i]{emm}[$state][$row][$col] = 1;
              } # if emm less than 1
            } # else
          } # if
        } # for my $col
      } # for my $row
# state-specific conditional end brackets
    } #for my $state
    #different
#    print "debug: mutate(): pop $i val : $pop[$i]{emm}[0][0][0]\n";     
#    for (my $j = 0; $j < @pop; $j++) {
#      print "\tdebug: mutate(): pop $j val : $pop[$j]{emm}[0][0][0]\n";   
#    }  
  } # for my $i
  # all emissions are the same here too
#  for (my $i = 0; $i < @pop; $i++) {
#    print "debug2: mutate(): pop $i val : $pop[$i]{emm}[0][0][0]\n";   
#  }
#    print "debug1: mutate(): end of mutate() pop scores\n";  
#    for (my $j = 0; $j < @pop; $j++) {
#      print "debug0: mutate(): pop $j val : $pop[$j]{emm}\n"; # they all refer to the same hash! pointer error!  
#      print "\tdebug0: mutate(): pop $j val : $pop[$j]{emm}[0]\n"; # they all refer to the same hash! pointer error!  
#      print "\t\tdebug0: mutate(): pop $j val : $pop[$j]{emm}[0][0]\n"; # they all refer to the same hash! pointer error!  
#      print "\tpop[$j]{score}: $pop[$j]{score}\n";
#    }  
  return(\@pop);  
}

sub evaluate {
  my @pop = @{$_[0]};
  my $template = $_[1];
  my $dir = $_[2];
  my $seq = $_[3];
  my @models;

  my $max_f = 0;

  @pop = sort{$b->{score}<=>$a->{score}} @pop; #FIXME check this line
#  print "debug: evaluate(): rows: " . @{$pop[0]{emm}[0]} . "\n"; #216 rows
  for(my $i = 0; $i < @pop ; $i++) {
    output_hmm($i, \@{$pop[$i]{emm}}, $template);
    push(@models, "$OUT_DIR$i.hmm");
  } # all hmms output are exactly the same
#  die; 
  my @scores = @{run_stochhmm(\@models, $dir, $seq)}; #FIXME change b/c eval should be in this function

  for(my $j = 0; $j < @pop; $j++) {
#    print "debug: evaluate(): score value j: $scores[$j]\n"; # only 0 has a score
    $pop[$j]{score} = $scores[$j];
    if ($scores[$j] > $max_f) {
      $max_f = $scores[$j];
    }
  }
  return($max_f, \@pop);
}

sub run_stochhmm {
# stochhmm -model $model -seq $fasta -posterior -threshold 0.9 -gff > $outdir/$outfile
  my @hmms = @{$_[0]};
  my $dir = $_[1];
  my $seq = $_[2];
  my @comm;
  my @evalcomm;
  my @evalresult;
  my @stats;
  my @scores;
  
#  print "debug: run_stochhmm(): size of hmms array " . @hmms . "\n"; #5
  for (my $n = 0; $n < @hmms; $n++) {
#    print "debug: run_stochhmm(): size of hmms[n] $hmms[$n] n $n\n"; #5
    push(@comm, "stochhmm -model $hmms[$n] -seq $seq -posterior -threshold 0.9 -gff > $dir$n.report");
    push(@evalcomm, "$EVAL_SCRIPT $dir$n.report $THRESHOLD"); #FIXME remove threshold since eval script doesn't use it
  }

  print "Running stochhmm\n";
  threading(\@comm, 0);
  print "Evaluating models\n";  ## FIXME this should be moved to evaluate function!
  @evalresult = @{threading(\@evalcomm, 1)}; 
  
  for (my $i = 0; $i < @evalresult; $i++) {
#    print "debug: run_stochhmm(): evalresult[i]: $evalresult[$i]\n";
#    for (my $j = 0; $j < @{$evalresult[$i]}; $j++) {
#      print "debug: run_stochhmm(): evalresult[i][j]: $evalresult[$i][$j]\n";
#      my ($hmmnum,$tp,$tn,$fp,$fn) = split(",",$evalresult[$i][$j]);
      my ($hmmnum,$tp,$tn,$fp,$fn) = split(",",$evalresult[$i]);
#      die "Died at $evalresult[$i][$j]\n" if not defined($tp);
      die "Died at $evalresult[$i]\n" if not defined($tp);
#      %{$stats[$hmmnum]} = ( #FIXME check syntax
#        tp => $tp,
#        fp => $fp,
#        tn => $tn,
#        fn => $fn
#      );
      $stats[$hmmnum]{tp} = $tp;
      $stats[$hmmnum]{fp} = $fp;
      $stats[$hmmnum]{tn} = $tn;
      $stats[$hmmnum]{fn} = $fn;
#    }
#    print "debug: run_stochhmm(): i $i\n"; # 0 1 2 3 4
#    print "debug: run_stochhmm(): hmmnum $hmmnum\n"; # always 0! 
#    print "debug: run_stochhmm(): size of stats " . @stats . "\n"; # size of stats is always 1! 
  }
  print "Done evaluating\n\n";

  for (my $k = 0; $k < @stats; $k++) {
    # FIXME reusing variables!
    my $tp = $stats[$k]{tp};
    my $fp = $stats[$k]{fp};
    my $tn = $stats[$k]{tn};
    my $fn = $stats[$k]{fn};

    $fn = $fn * 10; #weight

    my $sen = ($tp + $fn) == 0 ? 0 : $tp / ($tp + $fn);
    my $spe = ($tn + $fp) == 0 ? 0 : $tn / ($tn + $fp);
    my $pre = ($tp + $fp) == 0 ? 0 : $tp / ($tp + $fp);
    my $rec = ($tp + $fn) == 0 ? 0 : $tp / ($tp + $fn); #FIXME same as #sens : delete?
  
    my $f = ($pre + $rec) == 0 ? 0 : (2 * $pre * $rec) / ($rec + $pre);
    push (@scores, $f);
    print "\thmmfile $k\.hmm:\tf: $f\ttp $tp tn $tn fp $fp fn $fn\n";
  }

  return(\@scores);
}

sub threading {
  my @comm = @{$_[0]};
  my $save = $_[1];

#  print "debug: threading(): printing comm:\n";
#  for (my $d = 0; $d < @comm; $d++) {
#    print "\tcomm $d: $comm[$d]\n"; # commands are correct, eval probably isn't reading the hmm name properly
    # maybe this is why OO G_A cd's into the outdir.
    # yes, eval just takes the first number it sees : in this case 0 from 0.1out/ . Need to change this in eval. cp over eval script to new script with better parsing, continue using current eval scripts for runs of OO GA so that nothing breaks.
#  }

#  my $count = 0; #FIXME not used?
  my @results;

  for (my $i = 0; $i < int(@comm / $THREADS) + 1; $i++) {
    my $Q = new Thread::Queue;
    my $remaining = $i * $THREADS + $THREADS >= @comm ? @comm : $i * $THREADS + $THREADS; 
    my $totalQ = @comm;
    
    for (my $j = $i * $THREADS; $j < $remaining; $j++) {
      $Q->enqueue($comm[$j]);
    }
    $Q->end();
    my @threads; # FIXME rename this variable or $THREADS
  
    my $lastj = 0;
    
    for (my $j = 0; $j < $THREADS; $j++) {
      $threads[$j] = threads->create(\&worker, $j, $Q);
      $lastj = $j + 1;
      my $remainingQ = $Q->pending();
      last if not defined ($remainingQ) or $remainingQ == 0;
    }

    for (my $j = 0; $j < $lastj; $j++) { # FIXME change all the $j's!
      push(@results, @{$threads[$j]->join()}); #FIXME make sure this works!
      # for evaluate (perl script) the only difference is 
      # my @results = @{$threads[$j]->join()};
      # consider moving all this to a seperate threads subroutine
#      print "debug: threading(): j $j results size " . @results . "\n"; # okay
#      print "debug: threading(): results[j]: $results[$j]\n";
    }
  }

  if ($save) {
    return (\@results);
  }
  print "Done\n\n";
}

sub worker {
  my ($thread, $queue) = @_;
  my $tid = threads->tid;
  my @results;
  
  while ($queue->pending) {
    my $command = $queue->dequeue;
    next if not defined($command);
    my $results = `$command`;
    push (@results, $results); # FIXME change variable names!
  }
  return (\@results);
}

sub output_hmm {
  my $file = $OUT_DIR . "/" . $_[0] . ".hmm";
  my @emms = @{$_[1]};
  my $template = $_[2];

#  print "debug: output_hmm(): rows: " . @{$emms[0]} . "\n" ;#216 rows
#  print "debug: output_hmm(): " . $NUM_EMISSIONS**($ORDER-1) . "\n";#36
#  print "debug: output_hmm(): " . ($NUM_EMISSIONS+1)**($ORDER-1) . "\n";#49
#  print "debug: output_hmm(): " . ($NUM_EMISSIONS)**($ORDER) . "\n";#216

  open (TMP, "<", $template) or die "Could not open template: $template\n";
  open (OUT, ">", $file) or die "Could not open hmm outfile: $file\n";

  my $next_emm = 0;
  my $state = -1;
  my $block = "";

  while(<TMP>) {
    my $line = $_;
    $block .= $line unless $next_emm;
    chomp $line;

#    if ($line =~ /^@/) {
#      $next_emm = 1;
#      $state++;
#    }

    if ($next_emm) {
      print OUT "$block";      
#      for (my $row = 0; $row < $NUM_EMISSIONS**($ORDER-1); $row++) {
      for (my $row = 0; $row < $NUM_EMISSIONS**($ORDER); $row++) {
        for (my $col = 0; $col < $NUM_EMISSIONS; $col++) {
          print OUT "$emms[$state][$row][$col]\t";
        }
        print OUT "\n";
      }
      $block = "$line\n";
    }

    if ($line =~ /^@/) {
      $next_emm = 1;
      $state++;
    }

    if ($line =~ /\#\#\#\#\#\#/) {
      $next_emm = 0;
    } 
  }

  close TMP;
  close OUT;
}

sub purge {
  my @pop = @{$_[0]};
  my $dead = int(@pop * (1-$PARENT_PERCENT)) - 1;
#  print "debug: purge(): size of pop " . @pop . "\n";

#  @pop = @pop[(@pop - $dead)..(@pop - 1)]; #FIXME check if this works/causes problems with indicies
  @pop = @pop[0..(@pop - $dead)]; #FIXME check if this works/causes problems with indicies
#  print "debug: purge(): size of pop " . @pop . "\n";
  return(\@pop);
}

sub mate {
  my @pop = @{$_[0]};
#  print "debug: mate(): size of pop " . @pop . "\n";
#FIXME going to initially write it in the strange way from G_A, should change to something more sensible later

#  my $sum = 0;
#  my @scores;

#  for(my $i = 0; $i < @pop; $i++) {
#    push (@scores, $pop[$i]{score});
#    $sum+=$pop[$i]{score};
#  }

  while (@pop < $POP_SIZE) {
#    my $father = int(rand($sum));
#    my $mother = int(rand($sum));
#    my $father_iter = -1;
#    my $mother_iter = -1;
    my $father_iter = int(rand(scalar(@pop))); #FIXME +1 or -1?
    my $mother_iter = int(rand(scalar(@pop)));

#    my $running_sum = 0;
#    for (my $i = 0; $i < @scores; $i++) {
#      $running_sum += $scores[$i];

#      if ($father < $running_sum) {
#        $father_iter = $i;
#      }

#      if ($mother < $running_sum) {
#        $mother_iter = $i;
#      }

#      if ($mother_iter != -1 && $father_iter != -1) {
#        last;
#      }
#    }
#    print "debug: mate(): mother_iter $mother_iter father_iter $father_iter\n";
    #crossover

    if (rand(1) < $CROSSOVER_RATE) { #FIXME fix this function
#      my %new = (
#        score => 0, 
#        model => "@pop.hmm"
#      );
#      $new{emm} = @{crossover($pop[$father_iter]{emm}, $pop[$mother_iter]{emm})};
#      my @newarr; #FIXME bad way of doing this 
#      push(@newarr, \%new);
      my @newarr;
      $newarr[0]{score} = 0;
      $newarr[0]{model} = "@pop.hmm";
      $newarr[0]{emm} = @{crossover($pop[$father_iter]{emm}, $pop[$mother_iter]{emm})};
#      print "debug mate() : crossover conditional before mutate()\n";
      @newarr = @{mutate(\@newarr)};
      push(@pop, $newarr[0]);
    }
    else {
#      my %new = (
#        score => 0, 
#        model => "@pop.hmm"
#      );
      my @newarr;
      $newarr[0]{score} = 0;
      $newarr[0]{model} = "@pop.hmm";
  # NOTE debugging here
#      print "debug0 mate() : newarr score: $newarr[0]{score}\n"; # prints 0
      for (my $state = 0; $state < @{$pop[$father_iter]{emm}}; $state++) {
#        for (my $row = 0; $row < $NUM_EMISSIONS**($ORDER-1); $row++) {
        for (my $row = 0; $row < $NUM_EMISSIONS**($ORDER); $row++) {
          for (my $col = 0; $col < $NUM_EMISSIONS; $col++) {
            $newarr[0]{emm}[$state][$row][$col] = ($pop[$father_iter]{emm}[$state][$row][$col] + $pop[$mother_iter]{emm}[$state][$row][$col]) / 2;
#            print "debug: mate(): new emm: $new{emm}[$state][$row][$col]\n";
#             print "\tdebug0.1 mate() : newarr score: $newarr[0]{score}\n"; # prints 0
          }
        }
      } 
#      print "debug mate() : else before mutate()\n"; # FIXME HERE is the problem 
#      print "debug1 mate() : newarr score: $newarr[0]{score}\n"; # 
      @newarr = @{mutate(\@newarr)};
#      print "debug: mate(): newarr emm $newarr[0]{emm}\n";
#      print "debug mate() : newarr score: $newarr[0]{score}\n"; # not a HASH reference
      push(@pop, $newarr[0]);
    }
  }
#  for (my $i = 0; $i < @pop; $i++) {
#    if (!defined($pop[$i]{score})) {
#      print "$i not defined score!\n";
#      $pop[$i]{score} = 0;
#    }
#  }
#  print "debug: mate(): individual scores\n";
#  for (my $d = 0; $d < @pop ; $d++) {
#    print "\td: $d score: $pop[$d]{score}\n";
#  }
  return(\@pop);
}

sub crossover {
  my @father = @{$_[0]};
  my @mother = @{$_[1]};
  my @new;
  
#  my $cross_row = int(rand($NUM_EMISSIONS**($ORDER-1))) - 1;
  my $cross_row = int(rand($NUM_EMISSIONS**($ORDER))) - 1;
  my $cross_col = int(rand($NUM_EMISSIONS)) - 1;
  for (my $state = 0; $state < @father; $state++) {
#    for (my $row = 0; $row < $NUM_EMISSIONS**($ORDER-1); $row++) {
    for (my $row = 0; $row < $NUM_EMISSIONS**($ORDER); $row++) {
      if ($cross_row < $row) {
        my @line1 = @{$father[$state][$row]};
        push(@{$new[$state]}, @line1); #FIXME check this!
      }
      elsif ($cross_row == $row) {
        my @line1 = @{$father[$state][$row]};
        my @line2 = @{$mother[$state][$row]};
        for (my $col = 0; $col < $NUM_EMISSIONS; $col++) {
          if ($row < $cross_col) {
            $new[$state][$row][$col] = $line1[$col];
          }
          else {
            $new[$state][$row][$col] = $line2[$col];
          }
        }
      }
      else {
        my @line2 = @{$mother[$state][$row]};
        push(@{$new[$state]}, @line2); #FIXME check this!
      }
    }
  }
  return(\@new);
}
