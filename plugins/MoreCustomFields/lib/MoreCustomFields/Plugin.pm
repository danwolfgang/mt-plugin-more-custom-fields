package MoreCustomFields::Plugin;

use strict;
use warnings;

use MT 4.2;
use base qw(MT::Plugin);
use CustomFields::Util qw( get_meta save_meta field_loop _get_html );
use MT::Util qw( relative_date offset_time offset_time_list epoch2ts 
                 ts2epoch format_ts encode_html dirify );

use Text::CSV;

use MoreCustomFields::CheckboxGroup;
use MoreCustomFields::RadioButtonsWithInput;
use MoreCustomFields::SelectedEntries;
use MoreCustomFields::SelectedPages;
use MoreCustomFields::SingleLineTextGroup;

use Data::Dumper;

sub init_app {
    my $plugin = shift;
    my ($app) = @_;
    return if $app->id eq 'wizard';

    my $r = $plugin->registry;
    $r->{tags} = sub { _load_tags( $app, $plugin ) };
}

sub _load_tags {
    my $app  = shift;
    my $tags = {};

    # Grab the field definitions, then use those definitions to load the
    # appropriate objects. Finally, turn those into a block tag.
    my @field_defs = MT->model('field')->load({
        type => 'multi_use_single_line_text_group',
    });
    foreach my $field_def (@field_defs) {
        my $tag = $field_def->tag;
        # Load the objects (entry, author, whatever) based on the current
        # field definition.
        my $obj_type = $field_def->obj_type;
        my @objects = MT->model($obj_type)->load({
            blog_id => $field_def->blog_id
        });
        foreach my $obj (@objects) {
            my $basename = 'field.' . $field_def->basename;
            # Only continue if this object has some metadata saved. That is,
            # if the field has been used.
            if ($obj->$basename) {
                # Create the actual tag Use the tag name and append "Loop" to it.
                $tags->{block}->{$tag . 'Loop'} = sub {
                    my ( $ctx, $args, $cond ) = @_;
                    # Use the $obj_type to figure out what context we're in.
                    my $obj = $ctx->stash($obj_type);
                    # Then load the saved YAML
                    my $yaml = YAML::Tiny->read_string( $obj->$basename );
                    # The $field_name is the custom field basename.
                    foreach my $field_name ( keys %{$yaml->[0]} ) {
                        my $field = $yaml->[0]->{$field_name};
                        # Build the output tag content
                        my $out = '';
                        my $vars = $ctx->{__stash}{vars};
                        my $count = 0;
                        # The $group_num is the group order/parent of the values. Sort
                        # it so that they are displayed in the order they were saved.
                        foreach my $group_num ( sort keys %{$field} ) {
                            local $vars->{'__first__'} = ($count++ == 0);
                            local $vars->{'__last__'} = ($count == scalar keys %{$field});
                            # Add the keys and values to the output
                            foreach my $value ( keys %{$field->{$group_num}} ) {
                                $vars->{$value} = $field->{$group_num}->{$value};
                            }
                            defined( $out .= $ctx->slurp( $args, $cond ) ) or return;
                        }
                        return $out;
                    }
                };
            }
        }
    }
    
    return $tags;
}


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
#        single_line_text_group => {
#            label             => 'Single-Line Text Group',
#            column_def        => 'vblob',
#            order             => 101,
#            no_default        => 1,
#            options_delimiter => ',',
#            options_field     => sub { MoreCustomFields::SingleLineTextGroup::_options_field(); },
#            field_html        => sub { MoreCustomFields::SingleLineTextGroup::_field_html(); },
#            field_html_params => sub { MoreCustomFields::SingleLineTextGroup::_field_html_params(@_); },
#        },
        multi_use_single_line_text_group => {
            label             => 'Multi-Use Single-Line Text Group',
            column_def        => 'vblob',
            order             => 102,
            no_default        => 1,
            options_delimiter => ',',
            options_field     => sub { MoreCustomFields::SingleLineTextGroup::_options_field(); },
            field_html        => sub { MoreCustomFields::SingleLineTextGroup::_multi_field_html(); },
            field_html_params => sub { MoreCustomFields::SingleLineTextGroup::_multi_field_html_params(@_); },
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
        # Find the Single Line Text Group field
        # The "beacon" is used to always grab the text field. This will catch
        # an empty text field.
        if(m/^customfield_(.*?)_singlelinetextgroupcf_(.*?)_cb_beacon$/) { 
            my $user_field_name = $2;
            # Now look at the individual text field in the group to determine if 
            # it's checked.
            if( $app->param( /^customfield_(.*?)_singlelinetextgroupcf_$user_field_name$/ ) ) { 
                my $field_name = "customfield_$1_singlelinetextgroupcf_$user_field_name";

                # Store this field's data as YAML.
                my $yaml = YAML::Tiny->new;

                # If any options for this CF have already been read and set,
                # grab them so we can just continue appending to them.
                if ( $app->param("customfield_$1") ) {
                    $yaml = YAML::Tiny->read_string( $app->param("customfield_$1") );
                }

                # Write the YAML for the current field.
                $yaml->[0]->{$1}->{$user_field_name} = $app->param($field_name);

                # Turn that YAML into a plain old string.
                my $result = $yaml->write_string();

                # Save the new result to the *real* field name, which should be written to the DB.
                $app->param("customfield_$1", $result);

                # Destory the specially-assembled fields, because they make MT barf.
                $app->delete_param($field_name);
                $app->delete_param($field_name.'_cb_beacon');
            }
        }
        # Find the Multi-Use Single Line Text Group field
        # The "beacon" is used to always grab the text field. This will catch
        # an empty text field.
        if(m/^customfield_(.*?)_multiusesinglelinetextgroupcf_(.*?)_cb_beacon$/) { 
            my $user_field_name = $2;
            # Now look at the individual text field in the group to determine if 
            # it's checked.
            if( $app->param( /^customfield_(.*?)_multiusesinglelinetextgroupcf_$user_field_name$/ ) ) { 
                my $field_name = "customfield_$1_multiusesinglelinetextgroupcf_$user_field_name";
                
                # Use a group number to hold each group of text boxes together.
                my $group_num = 1;
                
                foreach my $field_value ( $app->param($field_name) ) {
                    # Store this field's data as YAML.
                    my $yaml = YAML::Tiny->new;

                    # If any options for this CF have already been read and set,
                    # grab them so we can just continue appending to them.
                    if ( $app->param("customfield_$1") ) {
                        $yaml = YAML::Tiny->read_string( $app->param("customfield_$1") );
                    }

                    # Write the YAML.
                    $yaml->[0]->{$1}->{$group_num}->{$user_field_name} = $field_value;
                    # Turn that YAML into a plain old string.
                    my $result = $yaml->write_string();

                    # Save the new result to the *real* field name, which
                    # should be written to the DB.
                    $app->param("customfield_$1", $result);

                    # Increment the group number so that the next text group 
                    # gets its own YAML key.
                    $group_num++;
                }

                # Destory the specially-assembled fields, because they make MT barf.
                $app->delete_param($field_name);
                $app->delete_param($field_name.'_cb_beacon');
                $app->delete_param($field_name.'_invisible')
            }
        }
    }

    1; # For some reason necessary to make author, category, and folder pages save without error.
}

1;

__END__
