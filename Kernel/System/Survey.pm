# --
# Kernel/System/Survey.pm - manage all survey module events
# Copyright (C) 2003-2006 OTRS GmbH, http://www.otrs.com/
# --
# $Id: Survey.pm,v 1.1 2006-03-11 09:46:25 mh Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

package Kernel::System::Survey;

use strict;

use vars qw(@ISA $VERSION);
$VERSION = '$Revision: 1.1 $';
$VERSION =~ s/^\$.*:\W(.*)\W.+?$/$1/;

sub new {
    my $Type = shift;
    my %Param = @_;
    # allocate new hash for object
    my $Self = {};
    bless ($Self, $Type);
    # check needed objects
    foreach (qw(DBObject ConfigObject LogObject TimeObject UserObject UserID)) {
        $Self->{$_} = $Param{$_} || die "Got no $_!";
    }

    return $Self;
}

sub SurveyList {
    my $Self = shift;
    my %Param = @_;
    my @List = ();
    # check needed stuff
    foreach (qw()) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    my $SQL = "SELECT id, number, title, master, valid, valid_once ".
        " FROM survey ORDER BY create_time DESC";
    $Self->{DBObject}->Prepare(SQL => $SQL);
    while (my @Row = $Self->{DBObject}->FetchrowArray()) {
        my %Data = ();

        $Data{SurveyID} = $Row[0];
        $Data{SurveyNumber} = $Row[1];
        $Data{SurveyTitle} = $Row[2];
        $Data{SurveyMaster} = $Row[3];
        $Data{SurveyValid} = $Row[4];
        $Data{SurveyValidOnce} = $Row[5];

        if ($Data{SurveyValid} eq 'No') {
            $Data{SurveyStatus} = 'New';

            if ($Data{SurveyValidOnce} eq 'Yes') {
                $Data{SurveyStatus} = 'Invalid';
            }
        } else {
            $Data{SurveyStatus} = 'Valid';

            if ($Data{SurveyMaster} eq 'Yes') {
                $Data{SurveyStatus} = 'Master';
            }
        }

        push(@List,\%Data);
    }

    return @List;
}

sub SurveyGet {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(SurveyID)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    my $SQL = "SELECT id, number, title, introduction, description, master, valid, create_time, create_by, change_time, change_by ".
        " FROM survey WHERE id=$Param{SurveyID}";
    $Self->{DBObject}->Prepare(SQL => $SQL);

    my %Data = ();
    while (my @Row = $Self->{DBObject}->FetchrowArray()) {
        $Data{SurveyID} = $Row[0];
        $Data{SurveyNumber} = $Row[1];
        $Data{SurveyTitle} = $Row[2];
        $Data{SurveyIntroduction} = $Row[3];
        $Data{SurveyDescription} = $Row[4];
        $Data{SurveyMaster} = $Row[5];
        $Data{SurveyValid} = $Row[6];
        $Data{SurveyCreateTime} = $Row[7];
        $Data{SurveyCreateBy} = $Row[8];
        $Data{SurveyChangeTime} = $Row[9];
        $Data{SurveyChangeBy} = $Row[10];
    }
    if (%Data) {
        my %CreateUserInfo = $Self->{UserObject}->GetUserData(
            UserID => $Data{SurveyCreateBy},
            Cached => 1
        );

        $Data{SurveyCreateUserLogin} = $CreateUserInfo{UserLogin};
        $Data{SurveyCreateUserFirstname} = $CreateUserInfo{UserFirstname};
        $Data{SurveyCreateUserLastname} = $CreateUserInfo{UserLastname};

        my %ChangeUserInfo = $Self->{UserObject}->GetUserData(
            UserID => $Data{SurveyChangeBy},
            Cached => 1
        );

        $Data{SurveyChangeUserLogin} = $ChangeUserInfo{UserLogin};
        $Data{SurveyChangeUserFirstname} = $ChangeUserInfo{UserFirstname};
        $Data{SurveyChangeUserLastname} = $ChangeUserInfo{UserLastname};
        return %Data;
    }
    else {
        $Self->{LogObject}->Log(Priority => 'error', Message => "No such SurveyID $Param{SurveyID}!");
        return ();
    }
}

sub SurveyChangeMaster {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(SurveyID)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    my $SQL = "SELECT master, valid ".
        " FROM survey WHERE id=$Param{SurveyID}";
    $Self->{DBObject}->Prepare(SQL => $SQL);

    my @Data = $Self->{DBObject}->FetchrowArray();

    if ($Data[1] eq 'No') {
        $Self->{DBObject}->Do(
            SQL => "UPDATE survey SET master = 'No' WHERE id = $Param{SurveyID}",
        );
    }
    else {
        if ($Data[0] eq 'Yes') {
            $Self->{DBObject}->Do(
                SQL => "UPDATE survey SET master = 'No' WHERE id = $Param{SurveyID}",
            );
        }
        else {
            $Self->{DBObject}->Do(
                SQL => "UPDATE survey SET master = 'No'",
            );
            $Self->{DBObject}->Do(
                SQL => "UPDATE survey SET master = 'Yes' WHERE id = $Param{SurveyID}",
            );
        }
    }
}

sub SurveyChangeValid {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(SurveyID)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    my $SQL = "SELECT master, valid ".
        " FROM survey WHERE id=$Param{SurveyID}";
    $Self->{DBObject}->Prepare(SQL => $SQL);

    my @Data = $Self->{DBObject}->FetchrowArray();

    if ($Data[0] eq 'No') {
        if ($Data[1] eq 'Yes') {
            $Self->{DBObject}->Do(
                SQL => "UPDATE survey SET valid = 'No' WHERE id = $Param{SurveyID}",
            );
        }
        else {
            my $SQL = "SELECT id ".
                " FROM survey_question WHERE survey_id=$Param{SurveyID}";
            $Self->{DBObject}->Prepare(SQL => $SQL);

            my @Quest = $Self->{DBObject}->FetchrowArray();

            if ($Quest[0] > '0') {
                my $SQL = "SELECT id ".
                    " FROM survey_question WHERE survey_id=$Param{SurveyID} AND (type='2' OR type='3')";
                $Self->{DBObject}->Prepare(SQL => $SQL);

                my $AllQuestionsAnsers = 'Yes';
                my @QuestionIDs = ();
                my $Counter1 = 0;

                while (my @Row = $Self->{DBObject}->FetchrowArray()) {
                    $QuestionIDs[$Counter1] = $Row[0];
                    $Counter1++;
                }

                foreach my $OneID(@QuestionIDs) {
                    $Self->{DBObject}->Prepare(SQL => "SELECT id FROM survey_answer WHERE question_id=$OneID");

                    my $Counter2 = '0';

                    while (my @Row = $Self->{DBObject}->FetchrowArray()) {
                        $Counter2++;
                    }

                    if ($Counter2 < 2) {
                        $AllQuestionsAnsers = 'no';
                    }
                }

                if ($AllQuestionsAnsers eq 'Yes')
                {
                    $Self->{DBObject}->Do(
                        SQL => "UPDATE survey SET valid = 'Yes' WHERE id = $Param{SurveyID}",
                    );
                    $Self->{DBObject}->Do(
                        SQL => "UPDATE survey SET valid_once = 'Yes' WHERE id = $Param{SurveyID}",
                    );
                }
            }
        }
    }
}

sub SurveySave {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(UserID SurveyID SurveyNumber SurveyTitle SurveyIntroduction SurveyDescription)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    $Self->{DBObject}->Do(
        SQL => "UPDATE survey SET ".
                         "number='$Param{SurveyNumber}', ".
                         "title='$Param{SurveyTitle}', ".
                         "introduction='$Param{SurveyIntroduction}', ".
                         "description='$Param{SurveyDescription}', ".
                         "change_time=current_timestamp, ".
                         "change_by=$Param{UserID} ".
                         "WHERE id = $Param{SurveyID}",
        );
}

sub SurveyNew {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(UserID SurveyNumber SurveyTitle SurveyIntroduction SurveyDescription)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    $Self->{DBObject}->Do(
        SQL => "INSERT INTO survey (number, title, introduction, description, master, valid, valid_once, create_time, create_by, change_time, change_by) VALUES (".
                                                         "'$Param{SurveyNumber}', ".
                                                         "'$Param{SurveyTitle}', ".
                                                         "'$Param{SurveyIntroduction}', ".
                                                         "'$Param{SurveyDescription}', ".
                                                         "'No', ".
                                                         "'No', ".
                                                         "'No', ".
                                                         "current_timestamp, ".
                                                         "$Param{UserID}, ".
                                                         "current_timestamp, ".
                                                         "$Param{UserID})"
        );

    my $SQL = "SELECT id FROM survey WHERE ".
                  "number='$Param{SurveyNumber}' AND ".
                  "title='$Param{SurveyTitle}' AND ".
                  "introduction='$Param{SurveyIntroduction}' AND ".
                  "description='$Param{SurveyDescription}' ".
                  "ORDER BY create_time DESC";
    $Self->{DBObject}->Prepare(SQL => $SQL);

    my @Row = $Self->{DBObject}->FetchrowArray();
    my $SurveyID = $Row[0];

    return $SurveyID;
}

sub QuestionList {
    my $Self = shift;
    my %Param = @_;
    my @List = ();
    # check needed stuff
    foreach (qw(SurveyID)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    my $SQL = "SELECT id, survey_id, question, type ".
        " FROM survey_question WHERE survey_id=$Param{SurveyID} ORDER BY position";
    $Self->{DBObject}->Prepare(SQL => $SQL);
    while (my @Row = $Self->{DBObject}->FetchrowArray()) {
        my %Data = ();

        $Data{QuestionID} = $Row[0];
        $Data{SurveyID} = $Row[1];
        $Data{Question} = $Row[2];
        $Data{QuestionType} = $Row[3];

        push(@List,\%Data);
    }

    return @List;
}

sub QuestionAdd {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(UserID SurveyID Question QuestionType)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    $Self->{DBObject}->Do(
        SQL => "INSERT INTO survey_question (survey_id, question, type, position, create_time, create_by, change_time, change_by) VALUES (".
                    "'$Param{SurveyID}', ".
                    "'$Param{Question}', ".
                    "'$Param{QuestionType}', ".
                    "'255', ".
                    "current_timestamp, ".
                    "$Param{UserID}, ".
                    "current_timestamp, ".
                    "$Param{UserID})"
        );
}

sub QuestionDelete {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(SurveyID QuestionID)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    $Self->{DBObject}->Do(
        SQL => "DELETE FROM survey_answer WHERE ".
                    "question_id='$Param{QuestionID}'"
        );
    $Self->{DBObject}->Do(
        SQL => "DELETE FROM survey_question WHERE ".
                    "id='$Param{QuestionID}' AND ".
                    "survey_id='$Param{SurveyID}'"
        );
}

sub QuestionSort {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(SurveyID)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    my $SQL = "SELECT id ".
        " FROM survey_question WHERE survey_id=$Param{SurveyID} ORDER BY position";
    $Self->{DBObject}->Prepare(SQL => $SQL);

    my $counter = 1;
    while (my @Row = $Self->{DBObject}->FetchrowArray()) {
        $Self->{DBObject}->Do(
            SQL => "UPDATE survey_question SET position='$counter' WHERE id=$Row[0]",
        );

        $counter++;
    }
}

sub QuestionUp {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(SurveyID QuestionID)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    $Self->{DBObject}->Prepare(SQL => "SELECT position ".
        " FROM survey_question WHERE id=$Param{QuestionID} AND survey_id=$Param{SurveyID}"
        );
    my @Row = $Self->{DBObject}->FetchrowArray();
    my $Position = $Row[0];

    if ($Position > '1')
    {
        my $PositionUp = $Position - 1;

        $Self->{DBObject}->Prepare(SQL => "SELECT id ".
            " FROM survey_question WHERE survey_id=$Param{SurveyID} AND position='$PositionUp'"
            );
        @Row = $Self->{DBObject}->FetchrowArray();
        my $QuestionIDDown = $Row[0];

        if ($QuestionIDDown ne '')
        {
            $Self->{DBObject}->Do(
                SQL => "UPDATE survey_question SET ".
                            "position='$Position' ".
                            "WHERE id='$QuestionIDDown'"
                );
            $Self->{DBObject}->Do(
                SQL => "UPDATE survey_question SET ".
                            "position='$PositionUp' ".
                            "WHERE id='$Param{QuestionID}'"
                );
        }
    }
}

sub QuestionDown {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(SurveyID QuestionID)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    $Self->{DBObject}->Prepare(SQL => "SELECT position ".
        " FROM survey_question WHERE id=$Param{QuestionID} AND survey_id=$Param{SurveyID}"
        );
    my @Row = $Self->{DBObject}->FetchrowArray();
    my $Position = $Row[0];

    if ($Position > '0')
    {
        my $PositionDown = $Position + 1;

        $Self->{DBObject}->Prepare(SQL => "SELECT id ".
            " FROM survey_question WHERE survey_id=$Param{SurveyID} AND position='$PositionDown'"
            );
        @Row = $Self->{DBObject}->FetchrowArray();
        my $QuestionIDUp = $Row[0];

        if ($QuestionIDUp ne '')
        {
            $Self->{DBObject}->Do(
                SQL => "UPDATE survey_question SET ".
                            "position='$Position' ".
                            "WHERE id='$QuestionIDUp'"
                );
            $Self->{DBObject}->Do(
                SQL => "UPDATE survey_question SET ".
                            "position='$PositionDown' ".
                            "WHERE id='$Param{QuestionID}'"
                );
        }
    }
}

sub QuestionGet {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(QuestionID)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    my $SQL = "SELECT id, survey_id, question, type, position, create_time, create_by, change_time, change_by ".
        " FROM survey_question WHERE id=$Param{QuestionID}";
    $Self->{DBObject}->Prepare(SQL => $SQL);

    my %Data = ();
    while (my @Row = $Self->{DBObject}->FetchrowArray()) {
        $Data{QuestionID} = $Row[0];
        $Data{SurveyID} = $Row[1];
        $Data{Question} = $Row[2];
        $Data{QuestionType} = $Row[3];
        $Data{QuestionPosition} = $Row[4];
        $Data{QuestionCreateTime} = $Row[5];
        $Data{QuestionCreateBy} = $Row[6];
        $Data{QuestionChangeTime} = $Row[7];
        $Data{QuestionChangeBy} = $Row[8];
    }

    return %Data;
}

sub QuestionSave {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(UserID QuestionID SurveyID Question)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    $Self->{DBObject}->Do(
        SQL => "UPDATE survey_question SET ".
                         "question='$Param{Question}', ".
                         "change_time=current_timestamp, ".
                         "change_by=$Param{UserID} ".
                         "WHERE id=$Param{QuestionID} ",
                         "AND survey_id=$Param{SurveyID}",
        );
}

sub QuestionCount {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(SurveyID)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    my $SQL = "SELECT COUNT(id) FROM survey_question WHERE survey_id='$Param{SurveyID}'";

    $Self->{DBObject}->Prepare(SQL => $SQL);
    my @CountQuestion = $Self->{DBObject}->FetchrowArray();

    return $CountQuestion[0];
}

sub AnswerList {
    my $Self = shift;
    my %Param = @_;
    my @List = ();
    # check needed stuff
    foreach (qw(QuestionID)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    my $SQL = "SELECT id, question_id, answer ".
        " FROM survey_answer WHERE question_id=$Param{QuestionID} ORDER BY position";
    $Self->{DBObject}->Prepare(SQL => $SQL);
    while (my @Row = $Self->{DBObject}->FetchrowArray()) {
        my %Data = ();

        $Data{AnswerID} = $Row[0];
        $Data{QuestionID} = $Row[1];
        $Data{Answer} = $Row[2];

        push(@List,\%Data);
    }

    return @List;
}

sub AnswerAdd {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(UserID QuestionID Answer)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    $Self->{DBObject}->Do(
        SQL => "INSERT INTO survey_answer (question_id, answer, position, create_time, create_by, change_time, change_by) VALUES (".
                    "'$Param{QuestionID}', ".
                    "'$Param{Answer}', ".
                    "'255', ".
                    "current_timestamp, ".
                    "$Param{UserID}, ".
                    "current_timestamp, ".
                    "$Param{UserID})"
        );
}

sub AnswerDelete {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(QuestionID AnswerID)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    $Self->{DBObject}->Do(
        SQL => "DELETE FROM survey_answer WHERE ".
                    "id='$Param{AnswerID}' AND ".
                    "question_id='$Param{QuestionID}'"
        );
}

sub AnswerSort {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(QuestionID)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    my $SQL = "SELECT id ".
        " FROM survey_answer WHERE question_id=$Param{QuestionID} ORDER BY position";
    $Self->{DBObject}->Prepare(SQL => $SQL);

    my $counter = 1;
    while (my @Row = $Self->{DBObject}->FetchrowArray()) {
        $Self->{DBObject}->Do(
            SQL => "UPDATE survey_answer SET position='$counter' WHERE id=$Row[0]",
        );

        $counter++;
    }
}

sub AnswerUp {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(QuestionID AnswerID)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    $Self->{DBObject}->Prepare(SQL => "SELECT position ".
        " FROM survey_answer WHERE id=$Param{AnswerID} AND question_id=$Param{QuestionID}"
        );
    my @Row = $Self->{DBObject}->FetchrowArray();
    my $Position = $Row[0];

    if ($Position > '1')
    {
        my $PositionUp = $Position - 1;

        $Self->{DBObject}->Prepare(SQL => "SELECT id ".
            " FROM survey_answer WHERE question_id=$Param{QuestionID} AND position='$PositionUp'"
            );
        @Row = $Self->{DBObject}->FetchrowArray();
        my $AnswerIDDown = $Row[0];

        if ($AnswerIDDown ne '')
        {
            $Self->{DBObject}->Do(
                SQL => "UPDATE survey_answer SET ".
                            "position='$Position' ".
                            "WHERE id='$AnswerIDDown'"
                );
            $Self->{DBObject}->Do(
                SQL => "UPDATE survey_answer SET ".
                            "position='$PositionUp' ".
                            "WHERE id='$Param{AnswerID}'"
                );
        }
    }
}

sub AnswerDown {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(QuestionID AnswerID)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    $Self->{DBObject}->Prepare(SQL => "SELECT position ".
        " FROM survey_answer WHERE id=$Param{AnswerID} AND question_id=$Param{QuestionID}"
        );
    my @Row = $Self->{DBObject}->FetchrowArray();
    my $Position = $Row[0];

    if ($Position > '0')
    {
        my $PositionDown = $Position + 1;

        $Self->{DBObject}->Prepare(SQL => "SELECT id ".
            " FROM survey_answer WHERE question_id=$Param{QuestionID} AND position='$PositionDown'"
            );
        @Row = $Self->{DBObject}->FetchrowArray();
        my $AnswerIDUp = $Row[0];

        if ($AnswerIDUp ne '')
        {
            $Self->{DBObject}->Do(
                SQL => "UPDATE survey_answer SET ".
                            "position='$Position' ".
                            "WHERE id='$AnswerIDUp'"
                );
            $Self->{DBObject}->Do(
                SQL => "UPDATE survey_answer SET ".
                            "position='$PositionDown' ".
                            "WHERE id='$Param{AnswerID}'"
                );
        }
    }
}

sub AnswerGet {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(AnswerID)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    my $SQL = "SELECT id, question_id, answer, position, create_time, create_by, change_time, change_by ".
        " FROM survey_answer WHERE id=$Param{AnswerID}";
    $Self->{DBObject}->Prepare(SQL => $SQL);

    my %Data = ();
    while (my @Row = $Self->{DBObject}->FetchrowArray()) {
        $Data{AnswerID} = $Row[0];
        $Data{QuestionID} = $Row[1];
        $Data{Answer} = $Row[2];
        $Data{AnswerPosition} = $Row[3];
        $Data{AnswerCreateTime} = $Row[4];
        $Data{AnswerCreateBy} = $Row[5];
        $Data{AnswerChangeTime} = $Row[6];
        $Data{AnswerChangeBy} = $Row[7];
    }

    return %Data;
}

sub AnswerSave {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(UserID AnswerID QuestionID Answer)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    $Self->{DBObject}->Do(
        SQL => "UPDATE survey_answer SET ".
                         "answer='$Param{Answer}', ".
                         "change_time=current_timestamp, ".
                         "change_by=$Param{UserID} ".
                         "WHERE id=$Param{AnswerID} ",
                         "AND question_id=$Param{QuestionID}",
        );
}

sub VoteList {
    my $Self = shift;
    my %Param = @_;
    my @List = ();
    # check needed stuff
    foreach (qw(SurveyID)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    my $SQL = "SELECT id, ticket_id, vote_time ".
        " FROM survey_request WHERE survey_id=$Param{SurveyID} AND public_survey_key='' ORDER BY vote_time";
    $Self->{DBObject}->Prepare(SQL => $SQL);
    while (my @Row = $Self->{DBObject}->FetchrowArray()) {
        my %Data = ();

        $Data{RequestID} = $Row[0];
        $Data{TicketID} = $Row[1];
        $Data{VoteTime} = $Row[2];

        push(@List,\%Data);
    }

    return @List;
}

sub VoteGet {
    my $Self = shift;
    my %Param = @_;
    my @List = ();
    # check needed stuff
    foreach (qw(RequestID QuestionID)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    my $SQL = "SELECT id, vote_value ".
        " FROM survey_vote WHERE request_id=$Param{RequestID} AND question_id=$Param{QuestionID}";
    $Self->{DBObject}->Prepare(SQL => $SQL);

    while (my @Row = $Self->{DBObject}->FetchrowArray()) {
        my %Data = ();
        $Data{RequestID} = $Row[0];
        $Data{VoteValue} = $Row[1] || '-';
        push(@List, \%Data);
    }

    return @List;
}




sub ValidOnce {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(SurveyID)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    $Self->{DBObject}->Prepare(SQL => "SELECT valid_once ".
        " FROM survey WHERE id=$Param{SurveyID}"
        );
    my @ValidOnce = $Self->{DBObject}->FetchrowArray();

    return $ValidOnce[0];
}

sub CountVote {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(QuestionID VoteValue)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    my $SQL = "SELECT COUNT(vote_value) FROM survey_vote WHERE question_id='$Param{QuestionID}' AND vote_value='$Param{VoteValue}'";

    $Self->{DBObject}->Prepare(SQL => $SQL);
    my @CountVote = $Self->{DBObject}->FetchrowArray();

    return $CountVote[0];
}

sub CountRequestComplete {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(SurveyID)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    my $SQL = "SELECT COUNT(id) FROM survey_request WHERE survey_id='$Param{SurveyID}' AND public_survey_key=''";

    $Self->{DBObject}->Prepare(SQL => $SQL);
    my @CountRequestComplete = $Self->{DBObject}->FetchrowArray();

    return $CountRequestComplete[0];
}

sub RequestSend {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(TicketID)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }

    my $PublicSurveyKey = "test";

    # sql for event
    $Self->{DBObject}->Prepare(SQL => "SELECT id ".
        " FROM survey WHERE master='yes' AND valid='yes' AND valid_once='yes'"
        );
    my @Master = $Self->{DBObject}->FetchrowArray();

    if ($Master[0] > 0) {
        $Self->{DBObject}->Do(
            SQL => "INSERT INTO survey_request (ticket_id, public_survey_key, send_time, survey_id) VALUES (".
                        "'$Param{TicketID}', ".
                        "'$PublicSurveyKey', ".
                        "current_timestamp, ".
                        "$Master[0])"
            );

    }
}





sub PublicSurveyGet {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(PublicSurveyKey)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    $Self->{DBObject}->Prepare(SQL => "SELECT survey_id ".
        " FROM survey_request WHERE public_survey_key='$Param{PublicSurveyKey}'"
        );
    my @SurveyID = $Self->{DBObject}->FetchrowArray();

    if ($SurveyID[0] > '0')
    {
        my $SQL = "SELECT id, number, title, introduction ".
            " FROM survey WHERE id=$SurveyID[0] AND valid='yes'";
        $Self->{DBObject}->Prepare(SQL => $SQL);

        my @Survey = $Self->{DBObject}->FetchrowArray();

        my %Data = ();
        if ($Survey[0] > '0') {
            $Data{SurveyID} = $Survey[0];
            $Data{SurveyNumber} = $Survey[1];
            $Data{SurveyTitle} = $Survey[2];
            $Data{SurveyIntroduction} = $Survey[3];

            return %Data;
        }
    }
}

sub PublicAnswerSave{
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(PublicSurveyKey QuestionID VoteValue)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    $Self->{DBObject}->Prepare(SQL => "SELECT id ".
        " FROM survey_request WHERE public_survey_key='$Param{PublicSurveyKey}'"
        );
    my @Row = $Self->{DBObject}->FetchrowArray();
    my $RequestID = $Row[0];

    if ($RequestID > '0') {
        $Self->{DBObject}->Do(
            SQL => "INSERT INTO survey_vote (request_id, question_id, vote_value, create_time) VALUES (".
                        "'$RequestID', ".
                        "'$Param{QuestionID}', ".
                        "'$Param{VoteValue}', ".
                        "current_timestamp)"
        );
    }
}

sub PublicSurveyKeyDelete {
    my $Self = shift;
    my %Param = @_;
    # check needed stuff
    foreach (qw(PublicSurveyKey)) {
      if (!defined ($Param{$_})) {
        $Self->{LogObject}->Log(Priority => 'error', Message => "Need $_!");
        return;
      }
    }
    # db quote
    foreach (keys %Param) {
        $Param{$_} = $Self->{DBObject}->Quote($Param{$_});
    }
    # sql for event
    $Self->{DBObject}->Prepare(SQL => "SELECT id ".
        " FROM survey_request WHERE public_survey_key='$Param{PublicSurveyKey}'"
        );
    my @Row = $Self->{DBObject}->FetchrowArray();
    my $RequestID = $Row[0];

    if ($RequestID > '0') {
        $Self->{DBObject}->Do(
            SQL => "UPDATE survey_request SET ".
                         "public_survey_key='', ".
                         "vote_time=current_timestamp ".
                         "WHERE id=$RequestID"
            );
    }
}


1;