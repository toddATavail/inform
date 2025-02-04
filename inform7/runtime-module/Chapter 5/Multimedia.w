[RTMultimedia::] Multimedia.

To compile the multimedia submodule for a compilation unit, which contains
_external_file, _figure and _sound packages.

@ Everything is done here:

=
void RTMultimedia::compile_files(void) {
	files_data *exf;
	LOOP_OVER(exf, files_data) {
		text_stream *desc = Str::new();
		WRITE_TO(desc, "external file '%W'", exf->name);
		Sequence::queue(&RTMultimedia::compilation_agent,
			STORE_POINTER_files_data(exf), desc);
	}
}

void RTMultimedia::compile_figures(void) {
	figures_data *bf;
	LOOP_OVER(bf, figures_data) {
		package_request *pack = RTInstances::package(bf->as_instance);
		Hierarchy::apply_metadata_from_number(pack, INSTANCE_FIGURE_ID_MD_HL,
			(inter_ti) bf->figure_number);
		Hierarchy::apply_metadata_from_filename(pack, INSTANCE_FIGURE_FILENAME_MD_HL,
			bf->filename_of_image_file);
	}
}

void RTMultimedia::compile_sounds(void) {
	sounds_data *bs;
	LOOP_OVER(bs, sounds_data) {
		package_request *pack = RTInstances::package(bs->as_instance);
		Hierarchy::apply_metadata_from_number(pack, INSTANCE_SOUND_ID_MD_HL,
			(inter_ti) bs->sound_number);
		Hierarchy::apply_metadata_from_filename(pack, INSTANCE_SOUND_FILENAME_MD_HL,
			bs->filename_of_sound_file);
	}
}

@ Files are made with the following agent, which makes a single |_external_file| package:

=
void RTMultimedia::compilation_agent(compilation_subtask *t) {
	files_data *exf = RETRIEVE_POINTER_files_data(t->data);
	wording W = exf->name;
	package_request *P = Hierarchy::local_package_to(EXTERNAL_FILES_HAP, exf->where_created);
	inter_name *exf_iname = Hierarchy::make_iname_with_memo(FILE_HL, P, W);
	inter_name *IFID_array_iname = NULL;
	if (exf->file_ownership == OWNED_BY_SPECIFIC_PROJECT) @<Make an ownership record@>;
	@<Make the file metadata array@>;
	@<Make the value metadata@>;
}

@<Make an ownership record@> =
	IFID_array_iname = Hierarchy::make_iname_with_memo(IFID_HL, P, W);
	packaging_state save =
		EmitArrays::begin_byte(IFID_array_iname, K_value);
	TEMPORARY_TEXT(II)
	WRITE_TO(II, "//%S//", exf->IFID_of_owner);
	LOOP_THROUGH_TEXT(pos, II)
		EmitArrays::numeric_entry((inter_ti) Str::get(pos));
	DISCARD_TEXT(II)
	EmitArrays::end(save);

@<Make the file metadata array@> =
	packaging_state save = EmitArrays::begin_word(exf_iname, K_value);
	EmitArrays::iname_entry(Hierarchy::find(AUXF_MAGIC_VALUE_HL));
	EmitArrays::iname_entry(Hierarchy::find(AUXF_STATUS_IS_CLOSED_HL));
	if (exf->file_is_binary) EmitArrays::numeric_entry(1);
	else EmitArrays::numeric_entry(0);
	EmitArrays::numeric_entry(0);
	TEMPORARY_TEXT(WW)
	WRITE_TO(WW, "%w", Lexer::word_raw_text(exf->unextended_filename));
	Str::delete_first_character(WW);
	Str::delete_last_character(WW);
	EmitArrays::text_entry(WW);
	DISCARD_TEXT(WW)
	switch (exf->file_ownership) {
		case OWNED_BY_THIS_PROJECT:
			EmitArrays::iname_entry(RTBibliographicData::IFID_iname()); break;
		case OWNED_BY_ANOTHER_PROJECT:
			EmitArrays::null_entry(); break;
		case OWNED_BY_SPECIFIC_PROJECT:
			EmitArrays::iname_entry(IFID_array_iname); break;
	}
	EmitArrays::end(save);

@<Make the value metadata@> =
	package_request *pack = RTInstances::package(exf->as_instance);
	Hierarchy::apply_metadata_from_iname(pack, INSTANCE_FILE_VALUE_MD_HL, exf_iname);
	Hierarchy::apply_metadata_from_raw_wording(pack, INSTANCE_LEAFNAME_MD_HL,
		Wordings::one_word(exf->unextended_filename));
	Hierarchy::apply_metadata_from_number(pack, INSTANCE_FILE_IS_BINARY_MD_HL,
		(inter_ti) exf->file_is_binary);
	switch (exf->file_ownership) {
		case OWNED_BY_THIS_PROJECT:
			Hierarchy::apply_metadata_from_number(pack, INSTANCE_FILE_OWNED_MD_HL, 1);
			break;
		case OWNED_BY_ANOTHER_PROJECT:
			Hierarchy::apply_metadata_from_number(pack, INSTANCE_FILE_OWNED_BY_OTHER_MD_HL, 1);
			break;
		case OWNED_BY_SPECIFIC_PROJECT:
			Hierarchy::apply_metadata(pack, INSTANCE_FILE_OWNER_MD_HL, exf->IFID_of_owner);
			break;
	}
