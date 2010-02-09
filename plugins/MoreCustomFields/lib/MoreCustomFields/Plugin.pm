package MoreCustomFields::Plugin;

use strict;
use warnings;

use MT 4.2;
use base qw(MT::Plugin);
use CustomFields::Util qw( get_meta save_meta field_loop _get_html );
use MT::Util
  qw( relative_date offset_time offset_time_list epoch2ts ts2epoch format_ts encode_html dirify );

use MoreCustomFields::CheckboxGroup;
use MoreCustomFields::RadioButtonsWithInput;
use MoreCustomFields::SelectedEntries;
use MoreCustomFields::SelectedPages;

sub load_customfield_types {
    my $checkbox_group = {
        checkbox_group => {
            label             => 'Checkbox Group',
            column_def        => 'vchar',
            order             => 301,
            no_default        => 1,
            options_delimiter => ',',
            options_field     => sub { MoreCustomFields::CheckboxGroup::_options_field(); },
            field_html        => sub { MoreCustomFields::CheckboxGroup::_field_html(); },
        },
        radio_input => {
            label             => 'Radio Buttons (with Input field)',
            column_def        => 'vchar',
            order             => 701,
            no_default        => 1,
            options_delimiter => ',',
            options_field     => sub { MoreCustomFields::RadioButtonsWithInput::_options_field(); },
            field_html        => sub { MoreCustomFields::RadioButtonsWithInput::_field_html(); },
            field_html_params => sub { MoreCustomFields::RadioButtonsWithInput::_field_html_params(@_); },
        },
        selected_entries => {
            label             => 'Selected Entries',
            column_def        => 'vchar',
            order             => 2000,
            no_default        => 1,
            options_delimiter => ',',
            options_field     => sub { MoreCustomFields::SelectedEntries::_options_field(); },
            field_html        => sub { MoreCustomFields::SelectedEntries::_field_html(); },
            field_html_params => sub { MoreCustomFields::SelectedEntries::_field_html_params(@_); },
        },
        selected_pages => {
            label             => 'Selected Pages',
            column_def        => 'vchar',
            order             => 2001,
            no_default        => 1,
            options_delimiter => ',',
            options_field     => sub { MoreCustomFields::SelectedPages::_options_field(); },
            field_html        => sub { MoreCustomFields::SelectedPages::_field_html(); },
            field_html_params => sub { MoreCustomFields::SelectedPages::_field_html_params(@_); },
        },
    };
}


sub post_save {
    my ($cb, $app, $obj) = @_;
    return unless $app->isa('MT::App');

    foreach ($app->param) {
        # The "beacon" is used to always grab the checkboxes. After all are 
        # captured, then we can check their status (checked or not).
        if(m/^customfield_(.*?)_checkboxgroupcf_(.*?)_cb_beacon$/) { 
            my $count = $2;
            # Now look at the individual checkbox in the group to determine if 
            # it's checked.
            if( $app->param( /^customfield_(.*?)_checkboxgroupcf_$count$/ ) ) { 
                my $field_name = "customfield_$1_checkboxgroupcf_$count";
                
                # This line serves two purposes:
                # - Create the "real" customfield to write to the DB, if it doesn't exist already.
                # - If the field has already been created (because this is the 2nd or 3rd or 4th etc
                #   Checkbox Group CF option) then get it so that we can see the currently-selected
                #   options and append a new result to them.
                my $customfield_value = $app->param("customfield_$1");

                # Join all the checkboxes into a list
                my $result;
                if ( $customfield_value ) { #only "join" if the field has already been set
                    $result = join ', ', $customfield_value, $app->param($field_name);
                }
                else { # Nothing saved yet? Just assign the variable
                    $result = $app->param($field_name);
                }

                # If the customfield held some results, then a real text value exists, such as "blue."
                # If the field was empty, however, the $results variable is empty, indicating that the
                # field should *not* be saved. This is incorrect because an empty field may be
                # purposefully unselected, so we need to force save the deletion of the field.
                if (!$result) { $result = ' '; }

                # Save the new result to the *real* field name, which should be written to the DB.
                $app->param("customfield_$1", $result);

                # Destory the specially-assembled fields, because they make MT barf.
                $app->delete_param($field_name);
                $app->delete_param($field_name.'_cb_beacon');
            }
        }
        # Find the Radio Buttons with Input field.
        elsif (m/^customfield_(.*?)_radiobuttonswithinput$/) {
            my $field_name = "customfield_$1_radiobuttonswithinput";

            # This is the text input value
            my $input_value = $app->param($field_name);

            if ($input_value) {
                # The "beacon" is the name of the last field.
                my $selected = $app->param($field_name."_beacon");

                # This is the selected radio button
                my $customfield_value = $app->param("customfield_$1");

                # Compare the beacon and selected value. Only if they match should the text input be saved.
                if ($selected eq $customfield_value) {
                    $customfield_value .= ': '.$input_value;
                }

                $app->param("customfield_$1", $customfield_value);
            }

            # Destroy the specially-assembled fields, because they make MT barf.
            $app->delete_param($field_name.'_beacon');
            $app->delete_param($field_name);
        }
        # Find the Selected Entries field.
        elsif( m/^customfield_(.*?)_selectedentriescf_(.*?)$/ ) {
            my $field_name = "customfield_$1_selectedentriescf_$2";
        
            # This is the text input value
            my $input_value = $app->param($field_name);

            # This line serves two purposes:
            # - Create the "real" customfield to write to the DB, if it doesn't exist already.
            # - If the field has already been created (because this is the 2nd or 3rd or 4th etc
            #   Selected Entry CF option) then get it so that we can see the currently-selected
            #   options and append a new result to them.
            my $customfield_value = $app->param("customfield_$1");

            my $result;
            # Join all the selected entries into a list
            if ( $customfield_value ) { #only "join" if the field has already been set
                if ($input_value eq '0') {
                    $result = $customfield_value;
                }
                else {
                    $result = join ',', $customfield_value, $input_value;
                }
                $result =~ s/^\s?,(.*)$/$1/;
            }
            else { # Nothing saved yet? Just assign the variable
                $result = $app->param($field_name);
            }

            # If the customfield held some results, then a real EntryID value exists, such as "12."
            # If the field was empty, however, the $results variable is empty, indicating that the
            # field should *not* be saved. This is incorrect because an empty field may be
            # purposefully unselected, so we need to force save the deletion of the field.
            if (!$result) { $result = ' '; }

            # Save the new result to the *real* field name, which should be written to the DB.
            $app->param("customfield_$1", $result);

            # Destroy the specially-assembled fields, because they make MT barf.
            $app->delete_param($field_name);
        } #end of Selected Entries field.
        # Find the Selected Pages field.
        elsif( m/^customfield_(.*?)_selectedpagescf_(.*?)$/ ) {
            my $field_name = "customfield_$1_selectedpagescf_$2";
    
            # This is the text input value
            my $input_value = $app->param($field_name);

            # This line serves two purposes:
            # - Create the "real" customfield to write to the DB, if it doesn't exist already.
            # - If the field has already been created (because this is the 2nd or 3rd or 4th etc
            #   Selected Page CF option) then get it so that we can see the currently-selected
            #   options and append a new result to them.
            my $customfield_value = $app->param("customfield_$1");

            my $result;
            # Join all the selected entries into a list
            if ( $customfield_value ) { #only "join" if the field has already been set
                if ($input_value eq '0') {
                    $result = $customfield_value;
                }
                else {
                    $result = join ',', $customfield_value, $input_value;
                }
                $result =~ s/^\s?,(.*)$/$1/;
            }
            else { # Nothing saved yet? Just assign the variable
                $result = $app->param($field_name);
            }

            # If the customfield held some results, then a real EntryID value exists, such as "12."
            # If the field was empty, however, the $results variable is empty, indicating that the
            # field should *not* be saved. This is incorrect because an empty field may be
            # purposefully unselected, so we need to force save the deletion of the field.
            if (!$result) { $result = ' '; }

            # Save the new result to the *real* field name, which should be written to the DB.
            $app->param("customfield_$1", $result);

            # Destroy the specially-assembled fields, because they make MT barf.
            $app->delete_param($field_name);
        } #end of Selected Pages field.
    }

    1; # For some reason necessary to make author, category, and folder pages save without error.
}

1;

__END__
