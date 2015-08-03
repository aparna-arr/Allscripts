#!/usr/bin/env perl
use warnings;
use strict;
use threads;
use Thread::Queue;

### Global Variables ###
## Set before running ##
my $MUTATION_RATE   = 0.1;
my $MAX_MUTATION    = 0.2;
my $CROSSOVER_RATE  = 0.05;
my $PARENT_PERCENT  = 0.2;
my $ORDER           = 3;
my $NUM_EMISSIONS   = 6;
my $THREADS         = 0;
my $EVAL_SCRIPT     = "../subscripts/eval_script.pl";
my $POP_SIZE        = 0;
my $OUT_DIR         = "";
###

# Default stochhmm command #
# stochhmm -model $model -seq $fasta -posterior -threshold 0.9 -gff > $outdir/$outfile

main();

sub main {

  my $usage = "
GA Stochhmm

usage : $0 <fasta sequence file> <initial hmm> <template HMM without emissions> <population size> <number of generations> <number of threads> <output dir/>
";

  my ($fasta, $model, $template, $pop, $gens, $threads, $outdir) = @ARGV;
  die $usage unless @ARGV == 7;

  #validate_input();
  print "\nGot input\n";

  $THREADS = $threads;  
  $POP_SIZE = $pop;     
  $OUT_DIR = $outdir;

  my @population = @{generate_population($model, $pop, $template, $outdir, $fasta)};
  # generates, mutates, evaluates

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

  my @emm = @{read_HMM($input_model)}; # returns a reference to a array  

  print "Done reading HMM\n";

  for (my $i = 0; $i < $popsize; $i++) {
    my @tempemm; # this is needed or else reference/pointer errors!
# FIXME try dclone instead of these loops
    for (my $n = 0; $n < @emm; $n++) {
      for (my $m = 0; $m < @{$emm[$n]}; $m++) {
        for (my $o = 0; $o < @{$emm[$n][$m]}; $o++) {
          $tempemm[$n][$m][$o] = $emm[$n][$m][$o];
        }
      }
    }

    push(@pop, {emm => \@tempemm, score => 0, model => "$i.hmm"});
  }

  @pop = @{mutate(\@pop)};
  ($max, $ref) = evaluate(\@pop, $template, $dir, $seq);
  @pop = @{$ref};

  print "Round 0 result: \tMAX: $max\n\n";
  print "Done initialization, now performing Genetic Algorithm\n";

  return(\@pop);
}

sub read_HMM {
  my $hmm = $_[0];
  my $next_emm = 0;
  my @states;
  my $states_num = -1;

  open (HMM, "<", $hmm) or die "Could not open $hmm\n";

  while(<HMM>) {
    my $line = $_;
    chomp $line;
    
    if ($next_emm && $line !~ /\#\#\#\#\#\#/) {
      my @row = split(/\s+/, $line) ; 
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

  return (\@states);
}

sub mutate {
  my @pop = @{$_[0]};

  for (my $i = 0; $i < @pop ; $i++) {
    for (my $state = 0; $state < @{$pop[$i]{emm}}; $state++) {
# state-specific mutation conditionals here
    if ($state == 4 || $state == 5) { # NOISY_MEDPEAK and NOISY_BROADPEAK
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
    } # if state-specific conditional
# state-specific conditional end brackets
    } #for my $state
  } # for my $i

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

  for(my $i = 0; $i < @pop ; $i++) {
    output_hmm($i, \@{$pop[$i]{emm}}, $template);
    push(@models, "$OUT_DIR$i.hmm");
  } 

  my @scores = @{run_stochhmm(\@models, $dir, $seq)}; #FIXME change b/c eval should be in this function

  for(my $j = 0; $j < @pop; $j++) {
    $pop[$j]{score} = $scores[$j];

    if ($scores[$j] > $max_f) {
      $max_f = $scores[$j];
    }
  }

  return($max_f, \@pop);
}

sub run_stochhmm {
  my @hmms = @{$_[0]};
  my $dir = $_[1];
  my $seq = $_[2];
  my @comm;
  my @evalcomm;
  my @evalresult;
  my @stats;
  my @scores;
  
  for (my $n = 0; $n < @hmms; $n++) {
    push(@comm, "stochhmm -model $hmms[$n] -seq $seq -posterior -threshold 0.9 -gff > $dir$n.report");
    push(@evalcomm, "$EVAL_SCRIPT $dir$n.report"); 
  }

  print "Running stochhmm\n";

  threading(\@comm, 0);

  print "Evaluating models\n";  ## FIXME this should be moved to evaluate function!

  @evalresult = @{threading(\@evalcomm, 1)}; 
  
  for (my $i = 0; $i < @evalresult; $i++) {
      my ($hmmnum,$tp,$tn,$fp,$fn) = split(",",$evalresult[$i]);
      die "Died at $evalresult[$i]\n" if not defined($tp);

      $stats[$hmmnum]{tp} = $tp;
      $stats[$hmmnum]{fp} = $fp;
      $stats[$hmmnum]{tn} = $tn;
      $stats[$hmmnum]{fn} = $fn;
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
      push(@results, @{$threads[$j]->join()}); 
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
  my $next_emm = 0;
  my $state = -1;
  my $block = "";

  open (TMP, "<", $template) or die "Could not open template: $template\n";
  open (OUT, ">", $file) or die "Could not open hmm outfile: $file\n";

  while(<TMP>) {
    my $line = $_;
    $block .= $line unless $next_emm;
    chomp $line;

    if ($next_emm) {
      print OUT "$block";      

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

  @pop = @pop[0..(@pop - $dead)]; 
  return(\@pop);
}

sub mate {
  my @pop = @{$_[0]};

  while (@pop < $POP_SIZE) {
    my $father_iter = int(rand(scalar(@pop))); #FIXME +1 or -1?
    my $mother_iter = int(rand(scalar(@pop)));

    #crossover
    if (rand(1) < $CROSSOVER_RATE) { 
      my @newarr;

      $newarr[0]{score} = 0;
      $newarr[0]{model} = "@pop.hmm";

      $newarr[0]{emm} = @{crossover($pop[$father_iter]{emm}, $pop[$mother_iter]{emm})};
      @newarr = @{mutate(\@newarr)};
      push(@pop, $newarr[0]);
    }
    else {
      my @newarr;

      $newarr[0]{score} = 0;
      $newarr[0]{model} = "@pop.hmm";

      for (my $state = 0; $state < @{$pop[$father_iter]{emm}}; $state++) {
        for (my $row = 0; $row < $NUM_EMISSIONS**($ORDER); $row++) {
          for (my $col = 0; $col < $NUM_EMISSIONS; $col++) {
            $newarr[0]{emm}[$state][$row][$col] = ($pop[$father_iter]{emm}[$state][$row][$col] + $pop[$mother_iter]{emm}[$state][$row][$col]) / 2;
          }
        }
      } 

      @newarr = @{mutate(\@newarr)};
      push(@pop, $newarr[0]);
    }
  }

  return(\@pop);
}

sub crossover {
  my @father = @{$_[0]};
  my @mother = @{$_[1]};
  my @new;
  
  my $cross_row = int(rand($NUM_EMISSIONS**($ORDER))) - 1;
  my $cross_col = int(rand($NUM_EMISSIONS)) - 1;

  for (my $state = 0; $state < @father; $state++) {
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
