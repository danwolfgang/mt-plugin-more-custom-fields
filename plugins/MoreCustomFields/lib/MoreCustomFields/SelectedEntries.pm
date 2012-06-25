package MoreCustomFields::SelectedEntries;

use strict;
use warnings;

use MT 4.2;
use base qw(MT::Plugin);
use MoreCustomFields::SelectedObject;

sub _options_field {
    return q{
<div class="textarea-wrapper">
    <input name="options" id="options" class="full-width" value="<mt:Var name="options" escape="html">" />
</div>
<p class="hint">Enter the ID(s) of the blog(s) whose entries should be available for selection. Leave this field blank to use the current blog only.</p>
<p class="hint">Blog IDs should be comma-separated (as in &rdquo;1,12,19,37,112&ldquo;), or the &rdquo;all&ldquo; value may be specified to include all blogs&rsquo; entries.</p>
    };
}

sub _field_html {
    return q{
<mt:SetVarBlock name="blogids"><mt:If name="options"><mt:Var name="options"><mt:Else><mt:Var name="blog_id"></mt:If></mt:SetVarBlock>

<ul class="custom-field-selected-entries" id="custom-field-selected-entries_<mt:Var name="field_name">" style="margin-top: 3px;">
<mt:Loop name="selectedentries_loop">
    <li style="padding-bottom: 3px;" id="li_<mt:Var name="field_name">_selectedentriescf_<mt:Var name="__counter__">">
        <mt:SetVarBlock name="selectedentry"><mt:Var name="field_selected"></mt:SetVarBlock>
        <input name="<mt:Var name="field_name">_selectedentriescf_<mt:Var name="__counter__">" id="<mt:Var name="field_name">_selectedentriescf_<mt:Var name="__counter__">" class="hidden" type="hidden" value="<mt:Var name="field_selected">" />
        <button
            style="background: #333 url('<mt:StaticWebPath>images/buttons/button.gif') no-repeat 0 center; border:none; border-top:1px solid #d4d4d4; font-weight: bold; font-size: 14px; line-height: 1.3; text-decoration: none; color: #eee; cursor: pointer; padding: 2px 10px 4px;"
            type="submit"
            onclick="return openDialog(this.form, 'mcf_list_entries', 'blog_id=<mt:Var name="blogids">&edit_field=<mt:Var name="field_name">_selectedentriescf_<mt:Var name="__counter__">')">
            Choose Entry
        </button>
        <span id="<mt:Var name="field_name">_selectedentriescf_<mt:Var name="__counter__">_preview" class="preview" style="padding-left: 8px;">
            <mt:Entries blog_ids="$blogids" lastn="999999" id="$selectedentry">
                <mt:EntryTitle>
            </mt:Entries>
        </span>
        <a style="padding: 3px 5px;" href="javascript:removeSelectedEntry('li_<mt:Var name="field_name">_selectedentriescf_<mt:Var name="__counter__">','<mt:Var name="field_name">');" title="Remove selected entry"><img src="<mt:StaticWebPath>images/status_icons/close.gif" width="9" height="9" alt="Remove selected entry" /></a>
    </li>
</mt:Loop>
</ul>
<p><a class="add-category-new-parent-link" href="javascript:addSelectedEntry('<mt:Var name="field_name">', '<mt:Var name="blogids">');">Add an entry</a></p>

    <input id="se-new-input-<mt:Var name="field_name">" style="display: none;" class="hidden" type="hidden" />
    <button
        style="display: none;"
        id="se-new-button-<mt:Var name="field_name">"
        type="submit">
        Choose Entry
    </button>
    <span id="se-new-preview-<mt:Var name="field_name">" class="preview" style="display: none;">
    </span>

<input type="hidden" id="se-adder-<mt:Var name="field_name">" value="1" />
    };
}

sub _field_html_params {
    my ($key, $tmpl_key, $tmpl_param) = @_;
    my $app = MT->instance;

    my $id       = $app->param('id');
    my $blog     = $app->blog;
    my $blog_id  = $blog ? $blog->id : 0;
    my $obj_type = $tmpl_param->{obj_type};

    my $field_name  = $tmpl_param->{field_name};

    # Several dropdowns may be needed, because several entries were selected.
    my $field_value = $tmpl_param->{field_value};
    
    # If there is no field value, there is nothing to parse. Likely on the
    # Edit Field screen.
    return unless $field_value;
    
    my @entryids = split(/,\s?/, $field_value);

    my @entryids_loop;
    foreach my $entryid (@entryids) {
        # Verify that $entryid is a number. If no Selected Entries are found, 
        # it's possible $entryid could be just a space character, which throws
        # an error. So, this check ensures we always have a valid entry ID.
        if ($entryid =~ m/\d+/) {
            push @entryids_loop, { field_basename => $field_name,
                                   field_selected => $entryid,
                                 };
        }
    }
    $tmpl_param->{selectedentries_loop} = \@entryids_loop;
}

sub tag_selected_entries {
    # The SelectedEntries tag will let you intelligently output the links you selected. Use:
    # <mt:SelectedEntries basename="selected_entries">
    #   <mt:If name="__first__">
    #     <ul>
    #   </mt:If>
    #     <li><a href="<mt:EntryPermalink>"><mt:EntryTitle></a></li>
    #   <mt:If name="__last__">
    #     </ul>
    #   </mt:If>
    # </mt:SelectedEntries>
    my ($ctx, $args, $cond) = @_;
    my $builder = $ctx->stash('builder');
    my $tokens  = $ctx->stash('tokens');
    my $res     = '';

    # The basename of the custom field you want to grab must be specified.
    # It's used later, to load the field data.
    my $cf_basename = $args->{basename};
    if (!$cf_basename) {
        return $ctx->error( 'The SelectedEntries block tag requires the basename argument. The basename should be the Selected Entries Custom Fields field basename.' );
    }

    # Grab the field name with the collected data from above. The basename 
    # must be unique so it's a good thing to key off of!
    my $field = CustomFields::Field->load( { type     => 'selected_entries',
                                             basename => $cf_basename, } );
    if (!$field) { return $ctx->error('A Selected Entries Custom Field with this basename could not be found.'); }

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
    my @entryids = split(/,\s?/, $object->$basename)
      if ($object && $object->$basename);
    my $i = 0;
    my $vars = $ctx->{__stash}{vars} ||= {};
    foreach my $entryid (@entryids) {
        # Verify that $entryid is a number. If no Selected Entries are found, 
        # it's possible $entryid could be just a space character, which throws
        # an error. So, this check ensures we always have a valid entry ID.
        if ($entryid =~ m/\d+/) {
            # Assign the meta vars
            local $vars->{__first__} = !$i;
            local $vars->{__last__} = !defined $entryids[$i + 1];
            local $vars->{__odd__} = ($i % 2) == 0; # 0-based $i
            local $vars->{__even__} = ($i % 2) == 1;
            local $vars->{__counter__} = $i + 1;
            # Assign the selected entry
            my $entry = MT::Entry->load( { id => $entryid, } );
            local $ctx->{__stash}{entry} = $entry;

            my $out = $builder->build($ctx, $tokens);
            if (!defined $out) {
                # A error--perhaps a tag used out of context. Report it.
                return $ctx->error( $builder->errstr );
            }
            $res .= $out;
            $i++; # Increment for the meta vars.
        }
    }
    return $res;
}

sub list_entries {
    my $app = shift;

    MoreCustomFields::SelectedObject::list_objects({
        app        => $app,
        blog_ids   => $app->param('blog_ids'),
        type       => 'entry',
        edit_field => $app->param('edit_field'),
        search     => $app->param('search') || '',
    });
}

1;

__END__
