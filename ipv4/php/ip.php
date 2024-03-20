<?php
/*
PHP Version 5.3+
*/
class Ipf {

    private $prefStart=array();
    private $prefEnd=array();
    private $endArr=array();
    private $fp;
    private $data;

    function __construct($path) {
        $this->fp = fopen($path, 'rb');
        $fsize = filesize($path);

        $this->data = fread( $this->fp, $fsize);

        for ($k = 0; $k < 256; $k++)
        {
            $i = $k * 8 + 4;
            $this->prefStart[$k] =$this->BytesToLong($this->data[$i], $this->data[$i+1], $this->data[$i+2], $this->data[$i+3]);
            $this->prefEnd[$k] =$this->BytesToLong($this->data[$i+4], $this->data[$i+5], $this->data[$i+6], $this->data[$i+7]);
        }

    }

    private function getByCur($i)
    {
        $p = 2052 + (intval($i) * 9);

        $offset =  $this->BytesToLong($this->data[4 + $p], $this->data[5 + $p], $this->data[6 + $p] ,$this->data[7 + $p]);
        $length =  ord($this->data[8 + $p]);
        fseek($this->fp, $offset);
        return fread($this->fp, $length);
    }



    function __destruct() {
        if ($this->fp !== NULL) {
            fclose($this->fp);
        }
    }

    function get($ip) {
        $val =sprintf("%u",ip2long($ip));
        $ip_arr = explode('.', $ip);
        $pref = $ip_arr[0];
        $low = $this->prefStart[$pref];
        $high =  $this->prefEnd[$pref];
        $cur = $low == $high ? $low : $this->Search($low, $high, $val);
        if ($cur == 100000000) {
            return "无信息";
        }
        return $this->getByCur($cur);
    }

    function Search($low, $high, $k) {
        $M = 0;

        for ($i = $low; $i < $high + 1; $i++) {
            $p = 2052 + ($i * 9);
            $this->endArr[$i] =$this->BytesToLong($this->data[$p], $this->data[$p+1], $this->data[$p+2], $this->data[$p+3]);
        }

        while ($low <= $high) {
            $mid = floor(($low + $high) / 2);
            $endipNum = $this->endArr[$mid];
            if ($endipNum >= $k) {
                $M = $mid;
                if ($mid == 0) {
                    break;
                }
                $high = $mid - 1;
            } else $low = $mid + 1;
        }
        return $M;
    }

    function BytesToLong($a, $b, $c, $d) {
        $iplong = (ord($a) << 0) | (ord($b) << 8) | (ord($c) << 16) | (ord($d) << 24);
        if ($iplong < 0) {
            $iplong+= 4294967296;//负数时
        };
        return $iplong;
    }

}

?>
