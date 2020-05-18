#---------------------------------------------------------------------------#
#Final Assignment                                                           #
#@Author: Julien Christen, Waleed Al-Hubaishi                               #
#@Project: Final Assignment                                                 #
#Part: time stamp                                                           #
#---------------------------------------------------------------------------#
use v5.26;
use strict;
#use warnings;
use experimental 'signatures';
use Time::localtime;
use List::Util qw(shuffle);
use Data::Dumper;
use Text::Trim qw(trim);
use List::MoreUtils qw(first_index);
use Lingua::StopWords qw( getStopWords );
use Math::Round;
use Text::Levenshtein 0.11 qw/ distance /;
use Cwd;
use List::Util qw(max);
use List::Util qw(min);
use Statistics::Basic qw(:all);
use Statistics::Basic::Mean;




##USER INPUT AREA#######################

#initialize the variables needed for the user inputs
my $decision;
my $para;
my $masterDirectory;
my $studentDirectory;
my $masterfileName;

my $studentName = undef;

#the scores of the students
my %hashOfStudentScores = ();

#the questions answered
my %hashOfansweredQuestions = ();

#the questions in Master file
my %hashOfMaster = ();

#array 
my @scoresValuesOnly = ();

#the chosen answers by words for each student
my %answeredQuestionsbyWords = ();




print "Welcome to Assignment 1b------------------------------------------------\n\n";
print "Is the Master File in your current working directory? Yes [y] or No [n]>";
$decision = <STDIN>;
chomp $decision;
if($decision eq "y" ||$decision eq "[y]" ||$decision eq "Yes" ||$decision eq "yes") {

    #get the current directory
    $masterDirectory = getcwd();
    print "your current working folder: $masterDirectory \n\n";

    print "Please enter the masterfile name>";
    #get the filename the user gave as input
    $masterfileName = <STDIN>;
    chomp $masterfileName;
    $masterfileName = trim $masterfileName;
    #check if the filename contains the extension .txt, if the user enters just the name => add .txt to the fileName
    $masterfileName = checkFileExtension($masterfileName);

    print "Please enter the students' files directory>";
    $studentDirectory= <STDIN>;
    chomp $studentDirectory;
    $studentDirectory = trim $studentDirectory;

} elsif($decision eq "n" ||$decision eq "[n]" ||$decision eq "No" ||$decision eq "no") {

    print "if not, then enter the absolute path to the masterfile directory>";
    $masterDirectory = <STDIN>;
    chomp $masterDirectory;
    $masterDirectory = trim $masterDirectory;

    print "enter the masterfile name>";
    $masterfileName = <STDIN>;
    chomp $masterfileName;
    $masterfileName = trim $masterfileName;
    $masterfileName = checkFileExtension($masterfileName);

    print "Please enter the students's files directory>";
    $studentDirectory = <STDIN>;
    chomp $studentDirectory;
    $studentDirectory = trim $studentDirectory;

#    read_from_file($directory, $fileName);
} else {
    print"No decision given";
}
########################################


my $counteras =0;
    opendir(my $directoryHandle, $studentDirectory) or die "Could not open '$studentDirectory' for reading: $!\n";

    while (my $studentsFile = readdir $directoryHandle) {
        if($studentsFile eq '.' or $studentsFile eq '..'){
            next;
        } else {
            print "Current student file : $studentsFile\n";
            $studentName = $studentsFile;
            $counteras++;
            #check if students file name contains the .txt extension or not
            $studentsFile = checkFileExtension($studentsFile);

            #the array which contains the questions and answers from the master file
            my @arrayOfAllMaster = construct_QandAarray($masterfileName, $masterDirectory);

            #print join (",", @arrayOfAllMaster."\n\n");

            #the hashmap which contains the questions as keys and answers as values from the arrayOfAllMaster
            my %hashOfQandAMaster = construct_model_answers(@arrayOfAllMaster);

            #the array which contains the questions and answers from the STUDENT file
            my @arrayOfAllStudent = construct_QandAarray($studentsFile, $studentDirectory);

            # #the hashmap which contains the questions as keys and answers as values from the arrayOfAllMaster
             my %hashOfQandAstudent = construct_model_answers(@arrayOfAllStudent);





            correct_an_exam(\%hashOfQandAMaster,\%hashOfQandAstudent);
        }

    }

      ########### STATISTICAL METHODS ###########

      #returns how many times a value occured
      sub check_occurence
      {
        #passing the parameters to its temporary variables
           my ( $hashToBeFilled_ref, $hashToLookIn_ref ) = @_;
           
           my %hashToLookIn = ();
           %hashToLookIn =  %$hashToLookIn_ref;
          
           my %hashToBeFilled = ();
           %hashToBeFilled = %$hashToBeFilled_ref;

           my $val = 0;

          foreach my $key ( keys %hashToLookIn ) {
          $val = $hashToLookIn{$key};
          $hashToBeFilled{$val}++;
          }

          return %hashToBeFilled;
      }

      #returns the standard deviaition
      sub stdev{
        my($data) = @_;
        if(@$data == 1){
                return 0;
        }
        my $average = &average($data);
        my $sqtotal = 0;
        foreach(@$data) {
                $sqtotal += ($average-$_) ** 2;
        }
        my $std = ($sqtotal / (@$data-1)) ** 0.5;
        return $std;
      }

      ################ SCORES ##################

      #print the correctly answered questions compared to the answered questoin
      for my $key(keys %hashOfansweredQuestions)
      {
        print "$key ............ $hashOfStudentScores{$key}/$hashOfansweredQuestions{$key}\n";
      }


      #sum of all values in hashOfStudentScores
      my $sumOfScores = 0;

      foreach my $score(values %hashOfStudentScores){
            $sumOfScores += $score;
          }

      #average of all values in hashOfStudentScores
      my $avgOfScores = $sumOfScores/scalar %hashOfStudentScores;

      #highest score in hash
      my $highestScore = max values %hashOfStudentScores;

      #lowest score in hash
      my $lowestScore = min values %hashOfStudentScores;

      #creating the occurence hash of each score
      my %hashOfOccurencesScoreTemp = ();
      my %hashOfOccurencesScore = check_occurence(\%hashOfOccurencesScoreTemp,\%hashOfStudentScores);

      my $occurenceOfMinScore = $hashOfOccurencesScore{$lowestScore};
      my $occurenceOfMaxScore = $hashOfOccurencesScore{$highestScore};


      printf "\n\n\n      Average number of correct Answeres ..... %.2f\n",$avgOfScores;
      print "                                Maximum  ..... $highestScore  ($occurenceOfMaxScore student(s))\n";
      print "                                Minimum  ..... $lowestScore  ($occurenceOfMinScore student(s))\n\n";



      ############# ANSWERED QUESTIONS ################

      #sum of all values in hashOfansweredQuestions
      my $sumOfAnswers = 0;

      foreach my $answer(values %hashOfansweredQuestions){
            $sumOfAnswers += $answer;
       }

       #average of all values in hashOfansweredQuestions
      my $avgOfAnsweredQuestions = $sumOfAnswers/scalar %hashOfansweredQuestions;

      #highest number of answered questions in hash
      my $maxNumOfAnsweredQuestions = max values %hashOfansweredQuestions;

      #lowest number of answered questions in hash
      my $minOfAnsweredQuestions = min values %hashOfansweredQuestions;

      #creating the occurence hash of each score
      my %hashOfOccurencesAnsweredQuestionsTemp = ();
      my %hashOfOccurencesAnsweredQuestions  = check_occurence(\%hashOfOccurencesAnsweredQuestionsTemp,\%hashOfansweredQuestions);

      my $occurenceOfMinAnswer = $hashOfOccurencesAnsweredQuestions{$minOfAnsweredQuestions};
      my $occurenceOfMaxAnswer = $hashOfOccurencesAnsweredQuestions{$maxNumOfAnsweredQuestions};

      printf "Average number of questions Answered ..... %.2f\n",$avgOfAnsweredQuestions;
      print "                            Maximum  ..... $maxNumOfAnsweredQuestions  ($occurenceOfMaxAnswer student(s))\n";
      print "                            Minimum  ..... $minOfAnsweredQuestions  ($occurenceOfMinAnswer student(s))\n\n\n";


      ############# BELOW EXPECTATIONS ################

      #number of questions

      print "Results below expectation: \n";
      my $numberOfQuestions = scalar %hashOfMaster; 

      #calculate the standard deviation
      my $standardDeviaition = stddev(@scoresValuesOnly);

      #calculate the mean of the scores (although it should be the same as the average)
      my $meanOfStudents = mean(@scoresValuesOnly);

      #calculate one standard deviation below the mean 
      my $oneStandardDeviationBelowMean = $meanOfStudents - $standardDeviaition;

      #go through all the students
      foreach my $student (keys %hashOfStudentScores)
      {

        #score is less than 50% of the total score
        if($hashOfStudentScores{$student} < ($numberOfQuestions/2)){

          print "$student ............. $hashOfStudentScores{$student}/$numberOfQuestions  (score < 50%)\n";
        }

        #score is less than one standard deviation than the mean
         if($hashOfStudentScores{$student} < $oneStandardDeviationBelowMean){
           print "$student ............. $hashOfStudentScores{$student}/$numberOfQuestions  (score < 1σ below mean)\n";

         }

      }

      #this will contain the sorted values of scores of the students
      my @sortedScores = ();

      #sort form the hashmap of the scores and put it inside the sortedscores array
      foreach my $name (sort { $hashOfStudentScores{$a} <=> $hashOfStudentScores{$b} } keys %hashOfStudentScores) {
          push(@sortedScores,"$name : $hashOfStudentScores{$name}");
      }

      #the indexes of the bottom 25% students
      my $bottomScores = round((scalar @sortedScores)*0.25);

      #get only the students within the bottom 25 % in this array
      my @arrayOfBottom = @sortedScores[0 .. ($bottomScores - 1)];

      for my $element(@arrayOfBottom)
      {
        #split the record from the array by ':' to get the name and the result in seperated strings 
        my ($k, $v) = split(/:/, $element, 2);
        print "$k ............. $v/$numberOfQuestions (bottom 25% of cohort)\n";
      }



      ##################### MISCONDUCT #################

          print "\n\nSimilar Pattern of Answers \n\n";

          #the hash of all occurences
          my %OccurenceHash = ();

          #an empty hash to the sub to fill all the occurences in
          my %hashToFillTemp = ();

          #the hash sent to the sub so it take the values and count the occurences
          my %hashToLookIn = %hashOfStudentScores;

          %OccurenceHash = check_occurence(\%hashToFillTemp,\%hashToLookIn);


          #go through all scores
         for my $score(keys %OccurenceHash)
         {

          #start looking for misconduct if the score is less than 21 and there is more than 2 occurences
          if(($OccurenceHash{$score} >= 2) && ($score < 21)){

            #array to fill with possible misconducters
            my @arrayToCompareMarks = ();
            
            for my $student(keys %hashToLookIn)
            {
              if($score == $hashToLookIn{$student}){
                push(@arrayToCompareMarks,$student); 
              }
            }


              #go through all the possible misconducts in array 
              for (my $i=0; $i <= ($#arrayToCompareMarks - 1); $i++) {

              my $student = @arrayToCompareMarks[$i];
              my $nextStudent = @arrayToCompareMarks[$i+1];



              # my $indexOfFirstAlternative = undef;

              # my $nextStudent = @arrayToCompareMarks[$indexOfFirstAlternative+1];


              #number of the questions answered
              my $answeredQuestionsStudentOne = $hashOfansweredQuestions{$student};
              my $answeredQuestionsStudentTwo = $hashOfansweredQuestions{$nextStudent};

             
              my $sameAnswersCounter = 0;

              #the answers by words
              my @answersOfStudentOne = split /\n/,$answeredQuestionsbyWords{$student};
              my @answersOfStudentTwo = split /\n/,$answeredQuestionsbyWords{$nextStudent};


              for my $answer(@answersOfStudentOne)
              {
                for my $answerTwo(@answersOfStudentTwo){

                  #check the same answers
                  if(normalizing_string($answer) eq normalizing_string($answerTwo))
                  {

                    $sameAnswersCounter++;
                  }
                }
              }

              if(defined $hashOfansweredQuestions{$student} && defined $hashOfansweredQuestions{$nextStudent} ){

              #if you found a match between all questions false and correct 
              if((normalizing_string($answeredQuestionsbyWords{$student})) eq  (normalizing_string($answeredQuestionsbyWords{$nextStudent}))){

              my $sumOfAnsweredquistionsInBoth = ($hashOfansweredQuestions{$student} + $hashOfansweredQuestions{$nextStudent});

              my $avgOfSum = $sumOfAnsweredquistionsInBoth;


              my $probability = $sumOfAnsweredquistionsInBoth/$avgOfSum;

                print "    $student \n";
                printf "and $nextStudent ...... probability : %.2f\n",$probability;
              }
              else
              {
                next;
              }
            }
          
            
          }
           }
         }
        
      ###################################################

      
    #checks the file extension of the $fileName, extends file name if the .txt extension isnt there
sub checkFileExtension($fileName) {

    if($fileName=~ m/\.txt/) {
        #return the original filename as the extension is already there
        return $fileName;

    } elsif($fileName =~ /\w/) {
        #add the .txt extension to the filename
        $fileName.=".txt";
        return $fileName;
    }
}

sub check_for_Levenshtein_distance($masterString, $studentString){
    if(defined $masterString && defined $studentString){

    #claculate the distance and neglect the dicartics letters ex:ç
    my $distance = distance($masterString, $studentString, {ignore_diacritics => 1});
    my $masterString_length = length($masterString);
    #calculate the 10% of the master line
    my $tenPercent_masterString = ($masterString_length/10);
    #check if the distance exceeds the 10%
    if(($distance <= $tenPercent_masterString ))
    {
        return 1;
    }
}

    return 0;
} 

sub correct_an_exam
{
    #passing the parameters to its temporary variables
     my ( $hashOfQandAMaster_ref, $arrayOfAllStudent_ref ) = @_;
     my %modelAnswers = ();
     %modelAnswers = %$hashOfQandAMaster_ref;
     my %studentQandA = ();
     %studentQandA =  %$arrayOfAllStudent_ref;
      my $correctAnswer = 0;



    #the counter to count the correct answers
    my $correctAnswers = 0;

    #the counter to count the answered questions
    my $answeredQuestions = 0;

	#loop thgouth the hash (questions)
      foreach my $key(sort keys %modelAnswers)
      {
      	my @alternativesFromMasterHash = ();
      	my $valueFromHash = undef;
        #the question from Master File is normailzed
      	my $normalizedKey = normalizing_string($key);
      	
      	#loop through the array of the student q and as
        foreach my $question (sort keys %studentQandA)
        {   


            my @studentAnswers = ();
            my $valueFromHashStudent = undef;
            #the question from student File is normailzed
            my $normalizedKeyStudent = normalizing_string($question);

            my $questionFromMaster = undef;

            my $questionFromStudent = undef;


            if(defined $normalizedKey && defined $normalizedKeyStudent){
                #if the question from master matches exactly the question from student
             if(check_for_Levenshtein_distance($normalizedKey,$normalizedKeyStudent) == 1)
                {
                    if($normalizedKey ne $normalizedKeyStudent)
                    {
                        print "Missing Question : $key \n used this instead $question \n\n";
                    }

                 $questionFromMaster = $key;
                 $questionFromStudent = $question;


                $valueFromHash = $modelAnswers{$key};
                #make an array with all alternatives related to the question 
                @alternativesFromMasterHash = split /\n/,$valueFromHash;

                $valueFromHashStudent = $studentQandA{$question};
                @studentAnswers = split /\n/,$valueFromHashStudent;

              
                #if one or more alternatives are missing
                if(scalar @studentAnswers != scalar @alternativesFromMasterHash)
                {
                  print "one alternative or more are missing \n";
                            
                }

                #those two arrays are made to check if one alternative is missing
                 my @alternativesOfMAster = @alternativesFromMasterHash;
                 my @alternativesOfStudent = @studentAnswers;

                 for my $alternativeMarkedMaster(@alternativesOfMAster)
                 {
                    #remove the X or x if found 
                    if($alternativeMarkedMaster =~ /\[\s*(x?|X?)\s*]/)
                    {
                        $alternativeMarkedMaster =~  s/\[x?]|\[X?]|\[ *]/\[ ]/;
                    }
                    
                 }

                 for my $alternativeMarkedStudent(@alternativesOfStudent)
                 {
                    if($alternativeMarkedStudent =~ /\[\s*(x?|X?)\s*]/)
                    {
                        $alternativeMarkedStudent =~  s/\[x?]|\[X?]|\[ *]/\[ ]/;
                    }
                 }

               

                    my $counterForChosenAnswers = 0;
                    my $chosenAnswer;
                    for my $alternative(@studentAnswers)
                    {
                        if(($alternative =~ /\n*\s*\[\s*(x|X)s*]\s+/) == 1)

                        {
                            $chosenAnswer = $alternative;
                            $counterForChosenAnswers++;
                        }
                    }
                                        
                        #if the student chosen more than one answer, neglect all choosed answers for the question
                        if($counterForChosenAnswers == 1) 
                        {
                            $answeredQuestionsbyWords{$studentName} .= $chosenAnswer."\n"; 
                            $answeredQuestions++;

                            #compare with the model answer
                            for my $alternativesFromMaster(@alternativesFromMasterHash)
                            {
                                if($alternativesFromMaster =~ /\n*\s*\[\s*(x|X)\s*]\s+/)
                                {
                                    $correctAnswer = $alternativesFromMaster;
                                    last;
                                }
                            }

                            #if the answers matched after Levenshtein
                            if(check_for_Levenshtein_distance(normalizing_string($correctAnswer),normalizing_string($chosenAnswer))){
                                #but they dont match 100%
                                if(normalizing_string($correctAnswer) ne normalizing_string($chosenAnswer)){
                                print "Missing answer : $correctAnswer \n Used this instead $chosenAnswer \n";
                            }
                                $correctAnswers++;
                            } 
                                          
                        }


                        elsif ($counterForChosenAnswers > 1)
                        {
                            print "The Student have chosen more than one answer for this question : $key \n\n\n";
                        }
                        elsif ($counterForChosenAnswers == 0)
                        {
                            print "The student didnt chose an answer for this question : $key  \n\n\n";
                        }

                        $normalizedKey = undef;
                        $normalizedKeyStudent = undef;
                             
                        delete $modelAnswers{$key};
                        delete $studentQandA{$question};

             }
          }
        }
     }

      
      if(scalar %modelAnswers != 0)
      {
      	foreach my $key(keys %modelAnswers)
      	{
      		print "This question is missing : $key \n";
      	}
      }

      if(scalar %studentQandA != 0)
      {
        print "I found also those questions in the Student file which were not corrected \n";
        foreach my $key(keys %studentQandA)
        {
            print "This question was found : $key \n";
        }
      }

      %hashOfMaster = %$hashOfQandAMaster_ref;

      if(defined $studentName){
     push(@scoresValuesOnly, $correctAnswers);
     $hashOfStudentScores{$studentName}= $correctAnswers;
     $hashOfansweredQuestions{$studentName} = $answeredQuestions;
     $studentName = undef;
   }

} 

sub normalizing_string($word)
{
	   #first of all removing the stop words then TRIM then removing the spaces between the words with the regex !!!!!!!!!!!!!
        if(defined $word){
        $word = lc $word;
        $word =~ s/\b(?:a|about|above|across|after|afterwards|the|a|an|and|it|or)\b//g; #removing the stop words
		$word = trim $word;
        $word =~ s/\h+/ /g;

        return $word;
    }
}

   
#construct an array which contains only questions and its relevant alternatives
sub construct_QandAarray($para,$dir) {

    my $flag = 0;
    my @questionsNanswersArray;

    open(my $fh, '<:encoding(UTF-8)', "$dir//$para")
        or die "Could not open file '$para' $!";

     # a container for multiple lines questions
     my $multipleLines;
     while (my $row = <$fh>) {
        chomp $row;
        
        #getting the questions
        if ($row =~ /\n*\s*30\.|[1-2][0-9]\.|[1-9]\.\s+/){
            $flag = 1;
             $multipleLines = $row;
            }

            #Add the rest of the question to it, in case of more than one line question 
            elsif (($row =~ /^\s*[A-Z]\.|[a-z]/ == 1) && (($row =~ /\n*\s*\[\s*(x?|X?)\s*]\s+/ ) == 0) && ($flag == 1)){
                $flag = 1;
                $multipleLines .= "\n".$row;
            }

            #getting the alternatives as well as writting the questions before that if the question was multiple lines question
            elsif ((($row =~ /^\n*\s*\[\s*(x?|X?)\s*]\s+/) == 1) && ($flag == 1)) {

              if(defined $multipleLines){ 
              push(@questionsNanswersArray,$multipleLines);
              $multipleLines = undef;
             }

             push(@questionsNanswersArray,$row);

            }
    }
     close $fh;

    return @questionsNanswersArray;
}

#construct a hashmap which contains the questions as key and the answers as the value
sub construct_model_answers(@arrayOFall)
     {

        my %modelHashmap = ();
        my $keyOfQuestion;

    
        for my $line(@arrayOFall)
        {   
            #getting the first line of the question 
            if (($line =~ /^\s*30\.|[1-2][0-9]\.|[1-9]\.\s?/ == 1) && ($line =~ /\n*\s?\[\s?(x?|X?)\s?]\s?/ ) == 0) {
			 $keyOfQuestion = $line;
            }

            #Add the rest of the question to it, in case of more than one line question 
        	elsif ((($line =~ /^\s?[A-Z]\.|[a-z]/) && ($line =~ /\n*\s?\[\s?(x?|X?)\s?]\s?/ ) == 0)){ 
			 $keyOfQuestion .= "\n".$line;
	    	}
            #assigning the answers as a value to the question related
            elsif (($line =~ /\n*\s*\[\s*(x?|X?)\s*]\s+/) == 1) {
            	my $indexOfFirstAlternative = undef;
				$indexOfFirstAlternative = first_index { $_ eq "$line" } @arrayOFall;
				 my $alternatives = undef;
                 if(defined $indexOfFirstAlternative){

				 while($arrayOFall[$indexOfFirstAlternative] =~ /\s*\[\s*(x?|X?)\.|x?\s*]\s+/)
					 {
					 	#getting all the alternatives inside the string to assign it to the questions later on
					 	$alternatives .= $arrayOFall[$indexOfFirstAlternative]."\n";
					 	$arrayOFall[$indexOfFirstAlternative] = "";
					 	$indexOfFirstAlternative++;	
						}
					}


            	 if(defined $keyOfQuestion){
              		$modelHashmap{$keyOfQuestion} = $alternatives;
                	$alternatives = undef;
           		 }
               $keyOfQuestion = undef;
            }
        }
        
        return %modelHashmap;
     }

