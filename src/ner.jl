using Flux, DataDeps, BSON, WordTokenizers
include("./NER_datadeps.jl")
include("./sequence_labelling.jl")

const NER_Char_UNK = '¿'
const NER_Word_UNK = "<UNK>"

struct NERmodel{M}
    model::M
end

function load_model_dicts(filepath)
    labels = BSON.load(joinpath(filepath, "labels.bson"))[:labels]
    chars_idx = BSON.load(joinpath(filepath, "char_to_embed_idx.bson"))[:get_char_index]
    words_idx = BSON.load(joinpath(filepath, "word_to_embed_idx.bson"))[:get_word_index]

    return remove_ner_label_prefix.([labels...]), chars_idx, words_idx
end

NERTagger() = NERTagger(datadep"NER Model Weights")

function NERTagger(weights_path)
    labels, chars_idx, words_idx = load_model_dicts(datadep"NER Model Dicts")
    model = BiLSTM_CNN_CRF_Model(labels, chars_idx, words_idx, chars_idx[NER_Char_UNK], words_idx[NER_Word_UNK], weights_path)
    NERmodel(model)
end

function (a::NERmodel)(sentence::String)
    a(tokenize(sentence))
    # a(tokenize(Languages.English(), sentence))
end

function (a::NERmodel)(tokens::Array{String,1})
    input_oh = [onehotinput(a.model, token) for token in tokens]
    return (a.model)(input_oh)
end

function remove_ner_label_prefix(str)
    str == "O" && return str
    str = str[3:end]
end
