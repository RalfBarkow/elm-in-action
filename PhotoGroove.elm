port module PhotoGroove exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import Array exposing (Array)
import Random
import Http
import Html.Attributes exposing (id, class, classList, src, name, type_, title, attribute, style, width, height, checked)
import Json.Decode exposing (string, int, list, Decoder)
import Json.Decode.Pipeline exposing (decode, required, optional)


port activateFilters : { url : String, filters : List { name : String, value : Float } } -> Cmd msg


applyFilters : Maybe String -> Cmd msg
applyFilters maybeUrl =
    case maybeUrl of
        Just url ->
            activateFilters
                { url = (urlPrefix ++ "large/" ++ url)
                , filters =
                    [ { name = "Hue", value = 0.75 }
                    , { name = "Ripple", value = 0.3 }
                    , { name = "Noise", value = 0.2 }
                    ]
                }

        Nothing ->
            Cmd.none


photoDecoder : Decoder Photo
photoDecoder =
    decode Photo
        |> required "url" string
        |> required "size" int
        |> optional "title" string "(untitled)"


urlPrefix : String
urlPrefix =
    "http://elm-in-action.com/"


type ThumbnailSize
    = Small
    | Medium
    | Large


paperSlider : List (Attribute msg) -> List (Html msg) -> Html msg
paperSlider =
    node "paper-slider"


view : Model -> Html Msg
view model =
    div [ class "content" ]
        [ h1 [] [ text "Photo Groove" ]
        , button
            [ onClick SurpriseMe ]
            [ text "Surprise Me!" ]
        , label [ id "activate-groove" ]
            [ paperSlider [] []
              --input [ type_ "checkbox", checked model.useFilters, onCheck SetUseFilters ] []
            , text "Activate Groove"
            ]
        , h3 [] [ text "Thumbnail Size:" ]
        , div [ id "choose-size" ]
            (List.map viewSizeChooser [ Small, Medium, Large ])
        , div [ id "thumbnails", class (sizeToString model.chosenSize) ]
            (List.map (viewThumbnail model.selectedUrl) model.photos)
        , viewLarge model
        ]


viewLarge : Model -> Html msg
viewLarge model =
    case model.selectedUrl of
        Just url ->
            if model.useFilters then
                canvas [ id "main-canvas", class "large" ] []
            else
                img [ class "large", src (urlPrefix ++ "large/" ++ url) ] []

        Nothing ->
            text ""


viewThumbnail : Maybe String -> Photo -> Html Msg
viewThumbnail selectedUrl thumbnail =
    img
        [ src (urlPrefix ++ thumbnail.url)
        , title (thumbnail.title ++ " [" ++ toString thumbnail.size ++ " KB]")
        , classList [ ( "selected", selectedUrl == Just thumbnail.url ) ]
        , onClick (SelectByUrl thumbnail.url)
        ]
        []


viewSizeChooser : ThumbnailSize -> Html Msg
viewSizeChooser size =
    label []
        [ input [ type_ "radio", name "size", onClick (SetSize size) ] []
        , text (sizeToString size)
        ]


sizeToString : ThumbnailSize -> String
sizeToString size =
    case size of
        Small ->
            "small"

        Medium ->
            "med"

        Large ->
            "large"


type alias Photo =
    { url : String
    , size : Int
    , title : String
    }


type alias Model =
    { photos : List Photo
    , useFilters : Bool
    , selectedUrl : Maybe String
    , loadingError : Maybe String
    , chosenSize : ThumbnailSize
    }


initialModel : Model
initialModel =
    { photos = []
    , selectedUrl = Nothing
    , loadingError = Nothing
    , chosenSize = Medium
    , useFilters = True
    }


type Msg
    = SelectByUrl String
    | SetUseFilters Bool
    | SelectAndFilter ( Int, Int )
    | SurpriseMe
    | SetSize ThumbnailSize
    | LoadPhotos (Result Http.Error (List Photo))


initialCmd : Cmd Msg
initialCmd =
    (list photoDecoder)
        |> Http.get "http://elm-in-action.com/photos/list.json"
        |> Http.send LoadPhotos


selectPhoto : Model -> Maybe String -> ( Model, Cmd Msg )
selectPhoto model maybeUrl =
    ( { model | selectedUrl = maybeUrl }, applyFilters maybeUrl )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SelectAndFilter ( index, filter ) ->
            let
                newSelectedUrl =
                    model.photos
                        |> Array.fromList
                        |> Array.get index
                        |> Maybe.map .url
            in
                selectPhoto model newSelectedUrl

        SelectByUrl url ->
            selectPhoto model (Just url)

        SurpriseMe ->
            let
                randomPhotoPicker =
                    Random.map2 (,)
                        (Random.int 0 (List.length model.photos - 1))
                        (Random.int 0 5)
            in
                ( model, Random.generate SelectAndFilter randomPhotoPicker )

        SetSize size ->
            ( { model | chosenSize = size }, Cmd.none )

        LoadPhotos result ->
            case result of
                Ok photos ->
                    let
                        selectedUrl =
                            Maybe.map .url (List.head photos)
                    in
                        ( { model | photos = photos, selectedUrl = selectedUrl }
                        , applyFilters selectedUrl
                        )

                Err error ->
                    ( { model | loadingError = Just "Error loading photos. Have you tried turning it off and on again?" }, Cmd.none )

        SetUseFilters useFilters ->
            ( { model | useFilters = useFilters }, applyFilters model.selectedUrl )


viewOrError : Model -> Html Msg
viewOrError model =
    case model.loadingError of
        Nothing ->
            view model

        Just errorMessage ->
            div [ class "error-message" ]
                [ h1 [] [ text "Photo Groove" ]
                , p [] [ text errorMessage ]
                ]


main : Program Never Model Msg
main =
    Html.program
        { init = ( initialModel, initialCmd )
        , view = viewOrError
        , update = update
        , subscriptions = (\_ -> Sub.none)
        }
