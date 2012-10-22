package MoreCustomFields::ReciprocalObject;

use strict;

use MT 4.2;
use base qw( MT::Plugin );

sub _options_field {
    return q{
<div class="textarea-wrapper">
    <input name="options"
        id="options"
        class="text full-width"
        value="<mt:Var name="options" escape="html">" />
</div>
<p class="hint">
    Enter the ID(s) of the blog(s) whose entries should be available for
    selection. Leave this field blank to use the current blog only. Blog IDs
    should be comma-separated (as in &rdquo;1,12,19,37,112&ldquo;), or the
    &rdquo;all&ldquo; value may be specified to include all blogs&rsquo;
    entries.
</p>
    };
}

sub _field_html_params {
    my ($key, $tmpl_key, $tmpl_param, $type) = @_;

    $tmpl_param->{recip_type}  = $type;
    $tmpl_param->{recip_types} = ($type eq 'entry') ? 'entries' : 'pages';

    my $obj = MT->model( $type )->load({
        id => $tmpl_param->{field_value},
    });

    if ($obj) {
        $tmpl_param->{obj_id}        = $obj->id;
        $tmpl_param->{obj_title}     = $obj->title;
        $tmpl_param->{obj_class}     = $obj->class;
        $tmpl_param->{obj_blog_id}   = $obj->blog_id;
        $tmpl_param->{obj_permalink} = $obj->permalink;
    }
}

sub _field_html {
    my ($type)   = @_;
    my $app      = MT->instance;
    my $obj_type = $app->param('_type');

    # Check that the field can be used here. The Reciprocal Entry Association
    # field type can be used only on entries, and the Reciprocal Page
    # Association field type can be used only on pages.
    if ( $obj_type ne $type ) {
        return qq{
            <p>
                The Reciprocal <mt:Var name="recip_type" capitalize="1">
                Association Custom Field type does not work on an object of
                type $obj_type.
            </p>
        };
    }
    else {
        return q{
<mt:SetVarBlock name="blogids"><mt:If name="options"><mt:Var name="options"><mt:Else><mt:Var name="blog_id"></mt:If></mt:SetVarBlock>

<div id="<mt:Var name="field_name">_status"
    class="<mt:If tag="Version" lt="5">mt4 </mt:If>msg-success custom-field-reciprocal-status"></div>

<input name="<mt:Var name="field_name">_reciprocal_<mt:Var name="recip_type">"
    id="<mt:Var name="field_name">"
    class="reciprocal-object hidden"
    type="hidden"
    value="<mt:Var name="field_value">" />

<a
<mt:If tag="Version" lt="5">
    onclick="return openDialog(this.form, 'mcf_list_<mt:Var name="recip_types">', 'blog_id=<mt:Var name="blogids">&edit_field=<mt:Var name="field_id">')"
<mt:Else>
    onclick="jQuery.fn.mtDialog.open('<mt:Var name="script_uri">?__mode=mcf_list_<mt:Var name="recip_types">&amp;blog_id=<mt:Var name="blogids">&amp;edit_field=<mt:Var name="field_id">')"
</mt:If>
    class="<mt:If tag="Version" lt="5">mt4-choose </mt:If>button">
    Choose <mt:Var name="recip_type">
</a>

<ul class="custom-field-reciprocal mcf-listing"
    id="custom-field-reciprocal-<mt:Var name="field_name">">
<mt:If name="field_value">
    <li id="obj-<mt:Var name="obj_id">">
        <span class="obj-title"><mt:Var name="obj_title"></span>
        <a href="<mt:Var name="script_uri">?__mode=view&amp;_type=<mt:Var name="obj_class">&amp;id=<mt:Var name="obj_id">&amp;blog_id=<mt:Var name="obj_blog_id">"
            class="edit"
            target="_blank"
            title="Edit in a new window."><img 
                src="<mt:StaticWebPath>images/status_icons/draft.gif"
                width="9" height="9" alt="Edit" /></a>
        <a href="<mt:Var name="obj_permalink">"
            class="view"
            target="_blank"
            title="View in a new window."><img
                src="<mt:StaticWebPath>images/status_icons/view.gif"
                width="13" height="9" alt="View" /></a>
        <img class="remove"
            alt="Remove selected entry"
            title="Remove selected entry"
            src="<mt:StaticWebPath>images/status_icons/close.gif"
            width="9" height="9" />
    </li>
</mt:If>
</ul>
        };
    }
}

# The ReciprocalEntry tag will enter the Entry context of the selected entry.
# <mt:ReciprocalEntry basename="my_reciprocal_entry">
#     <p><a href="<mt:EntryPermalink>"><mt:EntryTitle></a></p>
# </mt:ReciprocalEntry>
sub tag_reciprocal_entry {
    my ($ctx, $args, $cond, $type) = @_;
    my $builder = $ctx->stash('builder');
    my $tokens  = $ctx->stash('tokens');
    my $res     = '';

    $type = 'entry' if !$type;

    # The basename of the custom field you want to grab must be specified.
    # It's used later, to load the field data.
    my $cf_basename = $args->{basename};
    if (!$cf_basename) {
        return $ctx->error( 
            'The Reciprocal' . ucfirst($type) . ' block tag requires the '
            . 'basename argument. The basename should be the Reciprocal '
            . ucfirst($type) . ' Association Custom Field&rsquo;s field '
            . 'basename.'
        );
    }

    # Grab the field name with the collected data from above. The basename 
    # must be unique so it's a good thing to key off of!
    my $field = CustomFields::Field->load({
        type     => "reciprocal_$type",
        basename => $cf_basename,
    })
        or return $ctx->error(
            'A Reciprocal ' . ucfirst($type) . ' Association Custom Field '
            . 'with this basename could not be found.'
        );

    my $basename = 'field.'.$field->basename;

    # Use Custom Fields find_stashed_by_type to load the correct object. This
    # will decide if it's an entry, page, category, folder, or author archive,
    # then load the object and return it to us.
    use CustomFields::Template::ContextHandlers;
    my $object = eval {
        CustomFields::Template::ContextHandlers::find_stashed_by_type(
            $ctx, $field->obj_type
        )
    };
    return $ctx->error($@) if $@;

    # Create an array of the entry IDs held in the field.
    # $object->$basename is the lookup that actually grabs the data.
    my $entryid = $object->$basename
        if ($object && $object->$basename);

    # Verify that $entryid is a number. If no Selected Entries are found, 
    # it's possible $entryid could be just a space character, which throws
    # an error. So, this check ensures we always have a valid entry ID.
    if ($entryid && $entryid =~ m/\d+/) {
        # Assign the selected entry
        my $entry = MT->model( $type )->load({ id => $entryid, });
        if (!$entry) {
            MT->log({
                level     => MT->model('log')->INFO(),
                class     => $type,
                blog_id   => $field->blog_id,
                message   => "A reciprocal $type association was not "
                    . "published for source $type ID #"
                    . $ctx->{__stash}{entry}{column_values}{id} . " and "
                    . "destination ID #" . $entryid . " because the $type "
                    . "could not be loaded.",
            });
            return $res;
        }
        # Regardless of whether this is a Page or Entry, we always populate
        # the `entry` stash.
        local $ctx->{__stash}{entry} = $entry;

        my $out = $builder->build($ctx, $tokens);
        if (!defined $out) {
            # A error--perhaps a tag used out of context. Report it.
            return $ctx->error( $builder->errstr );
        }
        $res .= $out;
    }

    return $res;
}

# The ReciprocalPage tag will enter the Page context of the selected page. All
# we need to do is specify the proper type ("page") and jump to the
# tag_reciprocal_entry function to build this.
# <mt:ReciprocalPage basename="my_reciprocal_page">
#     <p><a href="<mt:PagePermalink>"><mt:PageTitle></a></p>
# </mt:ReciprocalPage>
sub tag_reciprocal_page {
    my ($ctx, $args, $cond) = @_;

    tag_reciprocal_entry($ctx, $args, $cond, 'page');
}

# This is called by MoreCustomFields::Plugin::post_save, which is the 
# post-save callback handler. Save the data for this custom field type.
sub _save {
    my ($arg_ref) = @_;
    my $app            = $arg_ref->{app};
    my $obj            = $arg_ref->{object};
    my $field_basename = $arg_ref->{field_basename};
    my $type = $obj->class;

    # Build the field names used in this field type.
    my $field_name = "customfield_${field_basename}_reciprocal_$type";

    # Grab the selected entry ID.
    my $recip_entry_id = $app->param($field_name);

    # Save the selected entry ID to the *real* custom field.
    $app->param("customfield_${field_basename}", $recip_entry_id);

    # Destory the specially-assembled fields, because they make MT barf.
    $app->delete_param($field_name);

    # Give up if there's no reciprocal ID, because that just means the field
    # isn't used.
    return unless $recip_entry_id;

    # Load the reciprocal entry and associate it with the current entry.
    my $recip_entry = MT->model( $type )->load({ id => $recip_entry_id });

    if (!$recip_entry) {
        MT->log({
            level     => MT->model('log')->WARNING(),
            class     => $type,
            author_id => $obj->author_id,
            blog_id   => $obj->blog_id,
            message   => "The $type specified in the Reciprocal "
                . ucfirst($type) . " Association custom field (source $type "
                . "ID #" . $obj->id . ") could not be loaded: $type ID #"
                . $recip_entry_id,
        });
        return;
    }

    my $cf_basename = 'field.' . $field_basename;

    # We need a "flag" to know if their is currently a reciprocal entry. If no
    # previous reciprocal entry, we want to note it in the Activity Log.
    my $flag = $recip_entry->$cf_basename;

    # Associate the current entry with the "other" entry.
    $recip_entry->$cf_basename( $obj->id );
    $recip_entry->save or die $recip_entry->errstr;

    MT->log({
        level     => MT->model('log')->INFO(),
        class     => $type,
        author_id => $obj->author_id,
        blog_id   => $obj->blog_id,
        message   => "A reciprocal $type association was created between \""
            . $obj->title . '" (ID ' . $obj->id . ') and "'
            . $recip_entry->title . '" (ID ' . $recip_entry->id . ').',
    })
        if !$flag;
}

# Reciprocal links need to be unlinked when deleted, removing the existing
# association in the database. Do this through an AJAX call to make a good 
# experience for the user and offer immediate feedback.
sub ajax_unlink {
    my $app = MT->instance;
    use MT::Util;
    my $basename       = $app->param('recip_field_basename');
    my $cur_entry_id   = $app->param('cur_entry_id');
    my $recip_entry_id = $app->param('recip_entry_id');
    my $recip_obj_type = $app->param('recip_obj_type');

    # The custom field basename is used for both the current entry and the
    # linked entry.
    $basename =~ s/customfield_/field./;

    # Remove the association from the linked entry.
    my $recip_entry = MT->model( $recip_obj_type )->load({ 
        id => $recip_entry_id,
    })
        or return MT::Util::to_json({ 
            status  => 0,
            message => "Error: couldn't load the associated $recip_obj_type.",
        });

    $recip_entry->$basename(undef);
    $recip_entry->save
        or return MT::Util::to_json({ 
            status  => 0,
            message => "Error: couldn't unlink the associated $recip_obj_type.",
        });

    # If there is no current entry ID, that means the current entry is a new,
    # unsaved entry. No need to do anything further.
    return MT::Util::to_json({
        status  => 1,
        message => "A reciprocal $recip_obj_type association was deleted for "
            . '&ldquo;' . $recip_entry->title . '.&rdquo;',
    })
        if !$cur_entry_id;

    # Now unlink the current entry association.
    my $cur_entry = MT->model( $recip_obj_type )->load({
        id => $cur_entry_id,
    })
        or return MT::Util::to_json({ 
            status  => 0,
            message => "Error: couldn't load the current $recip_obj_type.",
        });

    $cur_entry->$basename(undef);
    $cur_entry->save
        or return MT::Util::to_json({ 
            status  => 0,
            message => "Error: couldn't unlink the current $recip_obj_type.",
        });

    MT->log({
        level     => MT->model('log')->INFO(),
        class     => $recip_obj_type,
        author_id => $cur_entry->author_id,
        blog_id   => $cur_entry->blog_id,
        message   => "A reciprocal $recip_obj_type association was deleted "
            . 'between "' . $cur_entry->title . '" (ID ' . $cur_entry->id 
            . ') and "' . $recip_entry->title . '" (ID ' . $recip_entry->id 
            . ').',
    });

    return MT::Util::to_json({
        status  => 1,
        message => "Successfully deleted the reciprocal $recip_obj_type "
            . 'association between &ldquo;' . $cur_entry->title 
            . '&rdquo; and &ldquo;' . $recip_entry->title . '.&rdquo;',
    });
}

1;

__END__
