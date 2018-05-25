module PhotoFolders exposing (main)

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode exposing (Decoder)


type Folder
    = Folder
        { name : String
        , photoUrls : List String
        , subfolders : List Folder
        }


type alias Model =
    { selectedPhotoUrl : Maybe String
    , photos : Dict String Photo
    , root : Folder
    }


initialModel : Model
initialModel =
    { selectedPhotoUrl = Nothing
    , photos = Dict.empty
    , root = Folder { name = "Loading...", photoUrls = [], subfolders = [] }
    }


init : ( Model, Cmd Msg )
init =
    ( initialModel
    , modelDecoder
        |> Http.get "http://elm-in-action.com/folders/list"
        |> Http.send LoadPage
    )


modelDecoder : Decoder Model
modelDecoder =
    Decode.succeed
        { selectedPhotoUrl = Just "trevi"
        , photos =
            Dict.fromList
                [ ( "trevi", { title = "Trevi", relatedUrls = [ "coli", "fresco" ], size = 34, url = "trevi" } )
                , ( "fresco", { title = "Fresco", relatedUrls = [ "trevi" ], size = 46, url = "fresco" } )
                , ( "coli", { title = "Coliseum", relatedUrls = [ "trevi", "fresco" ], size = 36, url = "coli" } )
                ]
        , root =
            Folder
                { name = "Photos"
                , photoUrls = []
                , subfolders =
                    [ Folder
                        { name = "2016"
                        , photoUrls = [ "trevi", "coli" ]
                        , subfolders =
                            [ Folder { name = "outdoors", photoUrls = [], subfolders = [] }
                            , Folder { name = "indoors", photoUrls = [ "fresco" ], subfolders = [] }
                            ]
                        }
                    , Folder
                        { name = "2017"
                        , photoUrls = []
                        , subfolders =
                            [ Folder { name = "outdoors", photoUrls = [], subfolders = [] }
                            , Folder { name = "indoors", photoUrls = [], subfolders = [] }
                            ]
                        }
                    ]
                }
        }


type Msg
    = SelectPhotoUrl String
    | LoadPage (Result Http.Error Model)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SelectPhotoUrl url ->
            ( { model | selectedPhotoUrl = Just url }, Cmd.none )

        LoadPage (Ok newModel) ->
            ( newModel, Cmd.none )

        LoadPage (Err _) ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    let
        photoByUrl : String -> Maybe Photo
        photoByUrl url =
            Dict.get url model.photos

        selectedPhoto : Html Msg
        selectedPhoto =
            case Maybe.andThen photoByUrl model.selectedPhotoUrl of
                Just photo ->
                    viewSelectedPhoto photo

                Nothing ->
                    text ""
    in
    div [ class "content" ]
        [ div [ class "folders" ]
            [ h1 [] [ text "Folders" ]
            , viewFolder model.root
            ]
        , div [ class "selected-photo" ] [ selectedPhoto ]
        ]


main : Program Never Model Msg
main =
    Html.program { init = init, view = view, update = update, subscriptions = \_ -> Sub.none }


type alias Photo =
    { title : String
    , size : Int
    , relatedUrls : List String
    , url : String
    }


viewSelectedPhoto : Photo -> Html Msg
viewSelectedPhoto photo =
    div
        [ class "selected-photo" ]
        [ h2 [] [ text photo.title ]
        , img [ src (urlPrefix ++ "photos/" ++ photo.url ++ "/full") ] []
        , span [] [ text (toString photo.size ++ "KB") ]
        , h3 [] [ text "Related" ]
        , div [ class "related-photos" ]
            (List.map viewRelatedPhoto photo.relatedUrls)
        ]


viewRelatedPhoto : String -> Html Msg
viewRelatedPhoto url =
    img
        [ class "related-photo"
        , onClick (SelectPhotoUrl url)
        , src (urlPrefix ++ "photos/" ++ url ++ "/thumb")
        ]
        []


viewFolder : Folder -> Html Msg
viewFolder (Folder folder) =
    let
        subfolders =
            List.map viewFolder folder.subfolders
    in
    div [ class "folder" ]
        [ label [] [ text folder.name ]
        , div [ class "subfolders" ] subfolders
        ]


urlPrefix : String
urlPrefix =
    "http://elm-in-action.com/"
