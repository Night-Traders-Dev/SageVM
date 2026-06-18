# ----------------------------------------------------------------------------
# SageVM Makefile (Orchestrator for sagemake)
# ----------------------------------------------------------------------------

all:
	@python3 sagemake

install:
	@python3 sagemake --install

debug:
	@python3 sagemake --debug

rebuild-host:
	@python3 sagemake --rebuild-sage

clean:
	@rm -f sgvm sgvmc sagevm tests/*.sgvm
	@if [ -d ".deps/SageLang/core" ]; then \
		$(MAKE) -C .deps/SageLang/core clean; \
	fi

# Automated test suite for SGVM/SRVM coverage
test:
	@mkdir -p .deps/SageLang/core/include/curl
	@if [ ! -f .deps/SageLang/core/include/curl/curl.h ]; then \
		echo "#ifndef MOCK_CURL_H" > .deps/SageLang/core/include/curl/curl.h; \
		echo "#define MOCK_CURL_H" >> .deps/SageLang/core/include/curl/curl.h; \
		echo "typedef void CURL;" >> .deps/SageLang/core/include/curl/curl.h; \
		echo "typedef int CURLcode;" >> .deps/SageLang/core/include/curl/curl.h; \
		echo "#define CURLE_OK 0" >> .deps/SageLang/core/include/curl/curl.h; \
		echo "#define curl_easy_init() (void*)0" >> .deps/SageLang/core/include/curl/curl.h; \
		echo "#define curl_easy_setopt(...) CURLE_OK" >> .deps/SageLang/core/include/curl/curl.h; \
		echo "#define curl_easy_perform(...) CURLE_OK" >> .deps/SageLang/core/include/curl/curl.h; \
		echo "#define curl_easy_cleanup(...)" >> .deps/SageLang/core/include/curl/curl.h; \
		echo "#define curl_easy_strerror(...) \"\"" >> .deps/SageLang/core/include/curl/curl.h; \
		echo "struct curl_slist;" >> .deps/SageLang/core/include/curl/curl.h; \
		echo "#define curl_slist_append(...) (void*)0" >> .deps/SageLang/core/include/curl/curl.h; \
		echo "#define curl_slist_free_all(...)" >> .deps/SageLang/core/include/curl/curl.h; \
		echo "#endif" >> .deps/SageLang/core/include/curl/curl.h; \
	fi
	@if [ ! -f .deps/SageLang/core/sage ]; then \
		$(MAKE) -C .deps/SageLang/core LDFLAGS="-lm -lpthread -ldl" -j$$(nproc); \
	fi
	@$(MAKE) all
	@python3 tests/run_tests.py
