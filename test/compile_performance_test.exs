defmodule Maru.CompilePerformanceTest do
  use ExUnit.Case, async: true

  test "speed test" do
    defmodule Test do
      use Maru.Router, make_plug: true

      params do
        requires :foo, type: Map do
          optional :param01, keep_blank: true
          optional :param02, keep_blank: true
          optional :param03, keep_blank: true
          optional :param04, keep_blank: true
          optional :param05, keep_blank: true
          optional :param06, keep_blank: true
          optional :param07, keep_blank: true
          optional :param08, keep_blank: true
          optional :param09, keep_blank: true
          optional :param10, keep_blank: true
          optional :param11, keep_blank: true
          optional :param12, keep_blank: true
          optional :param13, keep_blank: true
          optional :param14, keep_blank: true
          optional :param15, keep_blank: true
          optional :param16, keep_blank: true
          optional :param17, keep_blank: true
          optional :param18, keep_blank: true
          optional :param19, keep_blank: true

          optional :param20, type: Map do
            optional :param21, keep_blank: true
            optional :param22, keep_blank: true
            optional :param23, keep_blank: true
            optional :param24, keep_blank: true
            optional :param25, keep_blank: true
            optional :param26, keep_blank: true
            optional :param27, keep_blank: true
            optional :param28, keep_blank: true
            optional :param29, keep_blank: true
            optional :param30, keep_blank: true
            optional :param31, keep_blank: true
            optional :param32, keep_blank: true
            optional :param33, keep_blank: true
            optional :param34, keep_blank: true
            optional :param35, keep_blank: true
            optional :param36, keep_blank: true
            optional :param37, keep_blank: true
            optional :param38, keep_blank: true

            optional :param39, type: Map do
              optional :param41, keep_blank: true
              optional :param42, keep_blank: true
              optional :param43, keep_blank: true
              optional :param44, keep_blank: true
              optional :param45, keep_blank: true
              optional :param46, keep_blank: true
              optional :param47, keep_blank: true
              optional :param48, keep_blank: true
              optional :param49, keep_blank: true
              optional :param50, keep_blank: true
              optional :param51, keep_blank: true
              optional :param52, keep_blank: true
              optional :param53, keep_blank: true
              optional :param54, keep_blank: true
              optional :param55, keep_blank: true
              optional :param56, keep_blank: true
              optional :param57, keep_blank: true
              optional :param58, keep_blank: true
              optional :param59, keep_blank: true
              optional :param60, keep_blank: true
            end

            optional :param40, type: Map do
              optional :param61, keep_blank: true
              optional :param62, keep_blank: true
              optional :param63, keep_blank: true
              optional :param64, keep_blank: true
              optional :param65, keep_blank: true
              optional :param66, keep_blank: true
              optional :param67, keep_blank: true
              optional :param68, keep_blank: true
              optional :param69, keep_blank: true
              optional :param70, keep_blank: true
              optional :param71, keep_blank: true
              optional :param72, keep_blank: true
              optional :param73, keep_blank: true
              optional :param74, keep_blank: true
              optional :param75, keep_blank: true
              optional :param76, keep_blank: true
              optional :param77, keep_blank: true
              optional :param78, keep_blank: true
              optional :param79, keep_blank: true

              optional :param80, type: Map do
                optional :param81, keep_blank: true
                optional :param82, keep_blank: true
                optional :param83, keep_blank: true
                optional :param84, keep_blank: true
                optional :param85, keep_blank: true
                optional :param86, keep_blank: true
                optional :param87, keep_blank: true
                optional :param88, keep_blank: true
                optional :param89, keep_blank: true
                optional :param90, keep_blank: true
                optional :param91, keep_blank: true
                optional :param92, keep_blank: true
                optional :param93, keep_blank: true
                optional :param94, keep_blank: true
                optional :param95, keep_blank: true
                optional :param96, keep_blank: true
                optional :param97, keep_blank: true
                optional :param98, keep_blank: true

                optional :param99, type: Map do
                  optional :param101, keep_blank: true
                  optional :param102, keep_blank: true
                  optional :param103, keep_blank: true
                  optional :param104, keep_blank: true
                  optional :param105, keep_blank: true
                  optional :param106, keep_blank: true
                  optional :param107, keep_blank: true
                  optional :param108, keep_blank: true
                  optional :param109, keep_blank: true
                  optional :param110, keep_blank: true
                  optional :param111, keep_blank: true
                  optional :param112, keep_blank: true
                  optional :param113, keep_blank: true
                  optional :param114, keep_blank: true
                  optional :param115, keep_blank: true
                  optional :param116, keep_blank: true
                  optional :param117, keep_blank: true
                  optional :param118, keep_blank: true
                  optional :param119
                  optional :param120
                end

                optional :param100, type: Map do
                  optional :param121, keep_blank: true
                  optional :param122, keep_blank: true
                  optional :param123, keep_blank: true
                  optional :param124, keep_blank: true
                  optional :param125, keep_blank: true
                  optional :param126, keep_blank: true
                  optional :param127, keep_blank: true
                  optional :param128, keep_blank: true
                  optional :param129, keep_blank: true
                  optional :param130, keep_blank: true
                  optional :param131, keep_blank: true
                  optional :param132, keep_blank: true
                  optional :param133, keep_blank: true
                  optional :param134, keep_blank: true
                  optional :param135, keep_blank: true
                  optional :param136, keep_blank: true
                  optional :param137, keep_blank: true
                  optional :param138, keep_blank: true

                  optional :param139, type: Map do
                    optional :param141, keep_blank: true
                    optional :param142, keep_blank: true
                    optional :param143, keep_blank: true
                    optional :param144, keep_blank: true
                    optional :param145, keep_blank: true
                    optional :param146, keep_blank: true
                    optional :param147, keep_blank: true
                    optional :param148, keep_blank: true
                    optional :param149, keep_blank: true
                    optional :param150, keep_blank: true
                    optional :param151, keep_blank: true
                    optional :param152, keep_blank: true
                    optional :param153, keep_blank: true
                    optional :param154, keep_blank: true
                    optional :param155, keep_blank: true
                    optional :param156, keep_blank: true
                    optional :param157, keep_blank: true
                    optional :param158, keep_blank: true
                    optional :param159, keep_blank: true
                    optional :param160, keep_blank: true
                  end

                  optional :param140, type: Map do
                    optional :param161, keep_blank: true
                    optional :param162, keep_blank: true
                    optional :param163, keep_blank: true
                    optional :param164, keep_blank: true
                    optional :param165, keep_blank: true
                    optional :param166, keep_blank: true
                    optional :param167, keep_blank: true
                    optional :param168, keep_blank: true
                    optional :param169, keep_blank: true
                    optional :param170, keep_blank: true
                    optional :param171, keep_blank: true
                    optional :param172, keep_blank: true
                    optional :param173, keep_blank: true
                    optional :param174, keep_blank: true
                    optional :param175, keep_blank: true
                    optional :param176, keep_blank: true
                    optional :param177, keep_blank: true
                    optional :param178, keep_blank: true
                    optional :param179, keep_blank: true

                    optional :param180, type: Map do
                      optional :param181, keep_blank: true
                      optional :param182, keep_blank: true
                      optional :param183, keep_blank: true
                      optional :param184, keep_blank: true
                      optional :param185, keep_blank: true
                      optional :param186, keep_blank: true
                      optional :param187, keep_blank: true
                      optional :param188, keep_blank: true
                      optional :param189, keep_blank: true
                      optional :param190, keep_blank: true
                      optional :param191, keep_blank: true
                      optional :param192, keep_blank: true
                      optional :param193, keep_blank: true
                      optional :param194, keep_blank: true
                      optional :param195, keep_blank: true
                      optional :param196, keep_blank: true
                      optional :param197, keep_blank: true
                      optional :param198, keep_blank: true
                      optional :param199, keep_blank: true
                      optional :param200, keep_blank: true
                    end
                  end
                end
              end
            end
          end
        end
      end

      def parameters(), do: @parameters

      get "/" do
        IO.inspect(conn)
        IO.inspect(params)
      end
    end

    # File.write!("parameters.out", "#{inspect(Test.parameters(), limit: :infinity)}")
  end
end
